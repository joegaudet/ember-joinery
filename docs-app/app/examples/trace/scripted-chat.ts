// A scripted conversation for the Trace examples: a small port of the parts of
// `@shadcn/helpers/ai-sdk` (`createChat()`) and the AI SDK's `useChat()` that upstream's
// examples use. A chat is scripted once, a user message and the assistant's reply, which
// reasons, calls tools, cites sources and writes text. `get()` reads the messages back
// complete; a `ChatSession` sends the user's message and streams the reply in, part by part
// and a word at a time, as `useChat()` does.
import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'

const waiter = buildWaiter('docs-app:trace-scripted-chat')

/** A text part, as the AI SDK's: the reply's words. */
export interface TextPart {
  type: 'text'
  text: string
  state: 'streaming' | 'done'
}

/** A reasoning part: the model's thinking. */
export interface ReasoningPart {
  type: 'reasoning'
  text: string
  state: 'streaming' | 'done'
}

/** A tool call, from its input to its output or error. */
export interface ToolPart {
  type: 'tool'
  toolName: string
  toolCallId: string
  state: 'input-available' | 'output-available' | 'output-error' | 'output-denied'
  input: { command: string }
  output?: { stdout: string }
  errorText?: string
}

/** A source the reply used. */
export interface SourceUrlPart {
  type: 'source-url'
  url: string
  title?: string
}

export type ChatPart = TextPart | ReasoningPart | ToolPart | SourceUrlPart

/** A message, shaped as the AI SDK's `UIMessage`. */
export interface ChatMessage {
  id: string
  role: 'user' | 'assistant'
  parts: ChatPart[]
}

/** A session's status, as `useChat()`'s: ready, sent and waiting, or streaming a reply. */
export type ChatStatus = 'ready' | 'submitted' | 'streaming'

/**
 * How long the stream waits, times this. The examples' tests set it to 0, so a reply streams
 * in at once; `settled()` waits for it either way.
 */
export const chatTiming = { scale: 1 }

/** The text of a message's text parts, joined, as upstream's `getMessageText`. */
export function getMessageText(message: Pick<ChatMessage, 'parts'>): string {
  return message.parts.reduce((text, part) => (part.type === 'text' ? text + part.text : text), '')
}

type Step =
  | { kind: 'text' | 'reasoning'; text: string; delayMs?: number }
  | { kind: 'sleep'; ms: number }
  | { kind: 'tool'; toolCallId: string; toolName: string; input: { command: string } }
  | { kind: 'output'; toolCallId: string; output: { stdout: string } }
  | { kind: 'error'; toolCallId: string; errorText: string }
  | { kind: 'source'; url: string; title?: string }

/** A tool call's handle: script its latency, then its output or its error. */
export interface ToolHandle {
  sleep(ms: number): ToolHandle
  output(output: { stdout: string }): ToolHandle
  error(errorText: string): ToolHandle
}

/** The writer an assistant turn is scripted with, as upstream's. */
export class ChatWriter {
  readonly steps: Step[] = []
  #tools = 0

  reasoning(text: string, options: { delayMs?: number } = {}): this {
    this.steps.push({ kind: 'reasoning', text, delayMs: options.delayMs })
    return this
  }

  text(text: string, options: { delayMs?: number } = {}): this {
    this.steps.push({ kind: 'text', text, delayMs: options.delayMs })
    return this
  }

  sleep(ms: number): this {
    this.steps.push({ kind: 'sleep', ms })
    return this
  }

  sourceUrl(source: { url: string; title?: string }): this {
    this.steps.push({ kind: 'source', ...source })
    return this
  }

  tool(toolName: string, options: { input: { command: string } }): ToolHandle {
    const toolCallId = `call-${(this.#tools += 1)}`
    this.steps.push({ kind: 'tool', toolCallId, toolName, input: options.input })
    const handle: ToolHandle = {
      sleep: ms => {
        this.steps.push({ kind: 'sleep', ms })
        return handle
      },
      output: output => {
        this.steps.push({ kind: 'output', toolCallId, output })
        return handle
      },
      error: errorText => {
        this.steps.push({ kind: 'error', toolCallId, errorText })
        return handle
      },
    }
    return handle
  }
}

/** Splits text into word-plus-whitespace deltas, as upstream's transport streams it. */
function deltas(text: string): string[] {
  return text.match(/\S+\s*/g) ?? [text]
}

/** Plays one step onto a message's parts, all at once: what a finished reply holds. */
function apply(parts: ChatPart[], step: Step): void {
  switch (step.kind) {
    case 'text':
    case 'reasoning':
      parts.push({ type: step.kind, text: step.text, state: 'done' })
      return
    case 'tool':
      parts.push({
        type: 'tool',
        toolName: step.toolName,
        toolCallId: step.toolCallId,
        state: 'input-available',
        input: step.input,
      })
      return
    case 'output':
    case 'error': {
      const index = parts.findIndex(
        part => part.type === 'tool' && part.toolCallId === step.toolCallId,
      )
      const tool = parts[index] as ToolPart
      parts[index] =
        step.kind === 'output'
          ? { ...tool, state: 'output-available', output: step.output }
          : { ...tool, state: 'output-error', errorText: step.errorText }
      return
    }
    case 'source':
      parts.push({ type: 'source-url', url: step.url, title: step.title })
      return
    case 'sleep':
      return
  }
}

/** A deterministic conversation: one user message and the assistant's scripted reply. */
export class ScriptedChat {
  #question: ChatMessage | undefined
  #steps: Step[] = []

  /** Scripts the user's message. */
  user(text: string): this {
    this.#question = { id: 'msg-1', role: 'user', parts: [{ type: 'text', text, state: 'done' }] }
    return this
  }

  /** Scripts the assistant's reply with a writer. */
  assistant(script: (context: { writer: ChatWriter }) => void): this {
    const writer = new ChatWriter()
    script({ writer })
    this.#steps = writer.steps
    return this
  }

  /** The first `count` messages, complete: all of them when omitted. */
  get(count = 2): ChatMessage[] {
    const parts: ChatPart[] = []
    for (const step of this.#steps) apply(parts, step)
    const reply: ChatMessage = { id: 'msg-2', role: 'assistant', parts }
    return [this.#question!, reply].slice(0, count).map(message => structuredClone(message))
  }

  /** The user message to send after a transcript, or `null` once it has been sent. */
  next(messages: readonly ChatMessage[]): ChatMessage | null {
    return messages.some(message => message.role === 'user')
      ? null
      : structuredClone(this.#question!)
  }

  /** The reply's steps, for a session to stream. */
  get steps(): readonly Step[] {
    return this.#steps
  }
}

/** Scripts a chat, as upstream's `createChat()`. */
export function createChat(): ScriptedChat {
  return new ScriptedChat()
}

/**
 * A conversation on screen, as `useChat()` gives one: its messages and status, a `send()` that
 * streams the scripted reply in after the user's message, and `setMessages()`. Given an
 * `owner` (the example's component), it lives as long as that does: once the owner is destroyed,
 * a reply that is streaming stops where it is, and so does the test waiter it holds.
 */
export class ChatSession {
  @tracked messages: ChatMessage[]
  @tracked status: ChatStatus = 'ready'
  readonly #chat: ScriptedChat
  /** The transport's delay between words, in milliseconds (upstream's `delayMs`). */
  readonly #delayMs: number
  #run = 0
  /** The stream's pending waits, each with what ends it early. */
  readonly #waits = new Map<ReturnType<typeof setTimeout>, () => void>()

  constructor(
    chat: ScriptedChat,
    options: { messages: ChatMessage[]; delayMs: number; owner?: object },
  ) {
    this.#chat = chat
    this.messages = options.messages
    this.#delayMs = options.delayMs
    if (options.owner) registerDestructor(options.owner, this.stop)
  }

  /** Whether a reply is on its way. */
  get busy(): boolean {
    return this.status === 'submitted' || this.status === 'streaming'
  }

  /** Replaces the messages, stopping a reply that is streaming. */
  setMessages = (messages: ChatMessage[]): void => {
    this.stop()
    this.status = 'ready'
    this.messages = messages
  }

  /**
   * Stops a reply that is streaming, leaving the messages and status as they are: the stream
   * ends at once (its pending wait too) and writes nothing more.
   */
  stop = (): void => {
    this.#run += 1
    for (const [timer, end] of this.#waits) {
      clearTimeout(timer)
      end()
    }
    this.#waits.clear()
  }

  /** Sends a user message and streams the scripted reply in. */
  send = (message: ChatMessage): void => {
    const run = (this.#run += 1)
    this.messages = [...this.messages, message]
    this.status = 'submitted'
    const token = waiter.beginAsync()
    void this.#stream(run).finally(() => waiter.endAsync(token))
  }

  #wait(ms: number): Promise<void> {
    return new Promise(resolve => {
      const timer = setTimeout(() => {
        this.#waits.delete(timer)
        resolve()
      }, ms * chatTiming.scale)
      this.#waits.set(timer, resolve)
    })
  }

  /** Puts the reply's parts back on screen after a change. */
  #show(run: number, reply: ChatMessage): boolean {
    if (run !== this.#run) return false
    this.messages = [...this.messages.slice(0, -1), { ...reply, parts: [...reply.parts] }]
    return true
  }

  async #stream(run: number): Promise<void> {
    await this.#wait(this.#delayMs)
    if (run !== this.#run) return
    const reply: ChatMessage = { id: 'msg-2', role: 'assistant', parts: [] }
    this.messages = [...this.messages, reply]
    this.status = 'streaming'
    for (const step of this.#chat.steps) {
      if (step.kind === 'sleep') {
        await this.#wait(step.ms)
        if (run !== this.#run) return
        continue
      }
      if (step.kind === 'text' || step.kind === 'reasoning') {
        // Each change is a new part, so what shows it renders again.
        const index = reply.parts.length
        let text = ''
        reply.parts.push({ type: step.kind, text, state: 'streaming' })
        for (const delta of deltas(step.text)) {
          await this.#wait(step.delayMs ?? this.#delayMs)
          text += delta
          reply.parts[index] = { type: step.kind, text, state: 'streaming' }
          if (!this.#show(run, reply)) return
        }
        reply.parts[index] = { type: step.kind, text, state: 'done' }
        if (!this.#show(run, reply)) return
        continue
      }
      apply(reply.parts, step)
      if (!this.#show(run, reply)) return
    }
    this.status = 'ready'
  }
}
