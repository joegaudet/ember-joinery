// A scripted conversation for the Message Scroller examples: a small port of the parts of
// `@shadcn/helpers/ai-sdk` (`createChat()`) and the AI SDK's `useChat()` that upstream's examples
// use. A chat is scripted once (`.user()`, `.sleep()`, `.assistant()`); `get()` reads its first
// messages back, `next()` finds the next user message to send after a transcript, and a session
// sends it and streams the scripted reply in, a word at a time, as `useChat()` does.
import { tracked } from '@glimmer/tracking'
import { buildWaiter } from '@ember/test-waiters'

// Each delay holds the test waiter, so `settled()` waits for a reply to finish streaming.
const waiter = buildWaiter('docs-app:scripted-chat')

interface Timer {
  id: ReturnType<typeof setTimeout>
  token: unknown
}

/** A text part of a message: all a scripted message has. */
export interface ChatTextPart {
  type: 'text'
  text: string
}

/** A message, shaped as the AI SDK's `UIMessage`. */
export interface ChatMessage {
  id: string
  role: 'user' | 'assistant'
  parts: ChatTextPart[]
}

/** A session's status, as `useChat()`'s: sent and waiting, streaming a reply, or done. */
export type ChatStatus = 'ready' | 'submitted' | 'streaming'

/**
 * How long the simulated stream waits, times this. The examples' tests set it to 0, so a reply
 * streams in at once; `settled()` waits for it either way.
 */
export const chatTiming = { scale: 1 }

/** The text of a message's parts, joined. */
export function getMessageText(message: Pick<ChatMessage, 'parts'>): string {
  return message.parts.reduce((text, part) => (part.type === 'text' ? text + part.text : text), '')
}

/** Splits text into word-plus-whitespace deltas, as upstream's transport streams it. */
function splitTextDeltas(text: string): string[] {
  return text.match(/\S+\s*/g) ?? [text]
}

const clone = (message: ChatMessage): ChatMessage => ({
  ...message,
  parts: message.parts.map(part => ({ ...part })),
})

interface Turn {
  message: ChatMessage
  /** How long to wait before the turn starts streaming: a `sleep()` scripted before it. */
  sleepMs: number
}

/** A deterministic conversation, scripted with `.user()`, `.sleep()` and `.assistant()`. */
export class ScriptedChat {
  readonly #turns: Turn[] = []
  readonly #reserved = new Set<string>()
  #index = 0
  #sleep = 0

  #id(id?: string): string {
    if (id) {
      this.#reserved.add(id)
      return id
    }
    let next: string
    do next = `msg-${++this.#index}`
    while (this.#reserved.has(next))
    this.#reserved.add(next)
    return next
  }

  #push(role: ChatMessage['role'], text: string, id?: string): this {
    this.#turns.push({
      message: { id: this.#id(id), role, parts: [{ type: 'text', text }] },
      sleepMs: this.#sleep,
    })
    this.#sleep = 0
    return this
  }

  /** Scripts a user turn. */
  user(text: string, options: { id?: string } = {}): this {
    return this.#push('user', text, options.id)
  }

  /** Scripts an assistant turn, streamed in a word at a time. */
  assistant(text: string, options: { id?: string } = {}): this {
    return this.#push('assistant', text, options.id)
  }

  /** Delays the next turn's stream. */
  sleep(delayMs: number): this {
    this.#sleep += delayMs
    return this
  }

  /** Copies of the first `count` scripted messages, or all of them. */
  get(count?: number): ChatMessage[] {
    return this.#turns.slice(0, count ?? this.#turns.length).map(turn => clone(turn.message))
  }

  /** The next scripted user message after this transcript, or `null` when none is left. */
  next(messages: readonly ChatMessage[]): ChatMessage | null {
    const index = this.#indexOf(messages.at(-1))
    for (let turn = index + 1; turn < this.#turns.length; turn++) {
      const message = this.#turns[turn]!.message
      if (message.role === 'user') return clone(message)
    }
    return null
  }

  /** Where a message is in the script, by its id, or else by its role and text. */
  #indexOf(message: ChatMessage | undefined): number {
    if (!message) return -1
    const byId = this.#turns.findIndex(turn => turn.message.id === message.id)
    if (byId !== -1) return byId
    const text = getMessageText(message)
    return this.#turns.findLastIndex(
      turn => turn.message.role === message.role && getMessageText(turn.message) === text,
    )
  }

  /** The scripted reply to the user message with this id, and the sleep before it. */
  replyTo(messageId: string): Turn | undefined {
    const index = this.#turns.findIndex(turn => turn.message.id === messageId)
    const reply = this.#turns[index + 1]
    return index !== -1 && reply?.message.role === 'assistant' ? reply : undefined
  }

  /**
   * A conversation in progress, as `useChat()` gives one: its messages and status, and
   * `sendMessage()`, which streams the scripted reply in `delayMs` apart per word.
   */
  session(options: { messages?: ChatMessage[]; delayMs?: number } = {}): ChatSession {
    return new ChatSession(this, options.messages ?? [], options.delayMs ?? 50)
  }
}

/** Scripts a conversation. */
export function createChat(): ScriptedChat {
  return new ScriptedChat()
}

/** A conversation in progress: `useChat()`'s messages, status, `sendMessage` and `setMessages`. */
export class ChatSession {
  @tracked messages: ChatMessage[]
  @tracked status: ChatStatus = 'ready'
  readonly #chat: ScriptedChat
  readonly #delayMs: number
  #timers: Timer[] = []

  constructor(chat: ScriptedChat, messages: ChatMessage[], delayMs: number) {
    this.#chat = chat
    this.messages = messages.map(clone)
    this.#delayMs = delayMs
  }

  /** The next scripted user message, or `null` when the script has run out. */
  get nextMessage(): ChatMessage | null {
    return this.#chat.next(this.messages)
  }

  /** Whether a reply is on its way. */
  get isBusy(): boolean {
    return this.status === 'submitted' || this.status === 'streaming'
  }

  /** Sends a user message, then streams its scripted reply in. */
  sendMessage = (message: ChatMessage): void => {
    this.messages = [...this.messages, clone(message)]
    const reply = this.#chat.replyTo(message.id)
    if (!reply) return
    this.status = 'submitted'
    const deltas = splitTextDeltas(getMessageText(reply.message))
    let text = ''
    const start = () => {
      this.status = 'streaming'
      this.messages = [...this.messages, { ...reply.message, parts: [{ type: 'text', text }] }]
      step(0)
    }
    const step = (index: number) => {
      if (index >= deltas.length) {
        this.status = 'ready'
        return
      }
      this.#after(this.#delayMs, () => {
        text += deltas[index]
        this.messages = this.messages.map(message =>
          message.id === reply.message.id
            ? { ...message, parts: [{ type: 'text', text }] }
            : message,
        )
        step(index + 1)
      })
    }
    this.#after(reply.sleepMs, start)
  }

  /** Replaces the transcript, stopping a reply on its way. */
  setMessages = (messages: ChatMessage[]): void => {
    this.stop()
    this.messages = messages.map(clone)
    this.status = 'ready'
  }

  /** Stops a reply on its way. Call it when the component that made the session goes. */
  stop = (): void => {
    for (const timer of this.#timers) {
      clearTimeout(timer.id)
      waiter.endAsync(timer.token)
    }
    this.#timers = []
  }

  #after(delayMs: number, callback: () => void): void {
    const timer: Timer = {
      token: waiter.beginAsync(),
      id: setTimeout(() => {
        this.#timers = this.#timers.filter(other => other !== timer)
        try {
          callback()
        } finally {
          waiter.endAsync(timer.token)
        }
      }, delayMs * chatTiming.scale),
    }
    this.#timers.push(timer)
  }
}
