import Component from '@glimmer/component'
import { registerDestructor } from '@ember/destroyable'
import { on } from '@ember/modifier'
import type Owner from '@ember/owner'
import { Lexer, type Token, type Tokens } from 'marked'
import { Bubble, Button, Message } from '@ember-joinery/ember'
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'
import { createChat, getMessageText, type ChatMessage } from './chat/scripted-chat.ts'

const response = `Wrap the value in a \`useDebounce\` hook. It returns the latest value once it stops changing for \`delay\` milliseconds.

\`\`\`tsx
export function useDebounce<T>(value: T, delay = 300) {
  const [debounced, setDebounced] = React.useState(value)

  React.useEffect(() => {
    const timeout = setTimeout(() => setDebounced(value), delay)
    return () => clearTimeout(timeout)
  }, [value, delay])

  return debounced
}
\`\`\`

Pass the debounced value to your fetch instead of the raw input.`

const chat = createChat().user('How do I debounce a search input in React?').assistant(response)

const transcript = chat.get()
const [question] = chat.get(1) as [ChatMessage]

/**
 * A fenced block whose closing fence hasn't arrived: upstream's `useIsCodeFenceIncomplete()`,
 * which is true only while the message streams (Streamdown's `isAnimating`).
 */
function isFenceIncomplete(token: Tokens.Code): boolean {
  const fence = /^ {0,3}(`{3,}|~{3,})/.exec(token.raw)?.[1]
  if (!fence) return false
  const lines = token.raw.trimEnd().split('\n')
  return lines.length < 2 || !lines.at(-1)!.trim().startsWith(fence)
}

/** A fenced code block, as upstream's `MarkdownCodeBlock` gets it. */
interface Fence {
  code: string
  language: string
  incomplete: boolean
}

/** A piece of a paragraph: text, or inline code. */
interface Inline {
  isCode: boolean
  text: string
}

/** One block of a message: a fenced code block or a paragraph. */
interface MarkdownBlock {
  fence: Fence | null
  inline: Inline[]
}

/**
 * The blocks of a message's Markdown, as Streamdown renders them with upstream's components:
 * paragraphs of text and inline code, and each fenced block as a Code Block. Streamdown parses
 * with remark; here `marked`'s lexer does, a dependency of the guide only.
 */
function blocks(text: string, streaming: boolean): MarkdownBlock[] {
  return Lexer.lex(text).flatMap((token: Token): MarkdownBlock[] => {
    if (token.type === 'code') {
      const code = token as Tokens.Code
      const fence = {
        code: code.text,
        language: code.lang?.split(/\s/)[0] ?? '',
        incomplete: streaming && isFenceIncomplete(code),
      }
      return [{ fence, inline: [] }]
    }
    if (token.type === 'paragraph') {
      const inline = ((token as Tokens.Paragraph).tokens ?? []).map(part => ({
        isCode: part.type === 'codespan',
        text: 'text' in part ? String(part.text) : part.raw,
      }))
      return [{ fence: null, inline }]
    }
    return []
  })
}

export default class CodeBlockMarkdown extends Component {
  session = chat.session({ messages: transcript, delayMs: 30 })

  constructor(owner: Owner, args: object) {
    super(owner, args)
    registerDestructor(this, this.session.stop)
  }

  get busy(): boolean {
    return this.session.isBusy
  }

  isUser = (message: ChatMessage) => message.role === 'user'
  textOf = (message: ChatMessage) => getMessageText(message)
  blocksOf = (message: ChatMessage) =>
    blocks(getMessageText(message), this.busy && message === this.session.messages.at(-1))

  replay = () => {
    this.session.setMessages([])
    this.session.sendMessage(question)
  }

  <template>
    {{!
      Upstream's useChat() on a scripted transport is the guide's scripted chat
      (./chat/scripted-chat.ts), and Streamdown's Markdown is marked's: see blocks() above.
    }}
    <div class="flex min-h-112 w-full max-w-md flex-col gap-4 py-6 text-sm">
      {{#each this.session.messages key="id" as |message|}}
        {{#if (this.isUser message)}}
          <Message @align="end" as |m|>
            <m.Content>
              <Bubble @align="end" @variant="muted" as |b|>
                <b.Content>{{this.textOf message}}</b.Content>
              </Bubble>
            </m.Content>
          </Message>
        {{else}}
          <Message as |m|>
            <m.Content>
              <div class="space-y-4 whitespace-normal [&>*:first-child]:mt-0 [&>*:last-child]:mb-0">
                {{#each (this.blocksOf message) as |block|}}
                  {{#if block.fence}}
                    <CodeBlock as |b|>
                      <b.Header>
                        <b.Title>{{if block.fence.language block.fence.language "text"}}</b.Title>
                        <b.Actions>
                          <b.CopyButton
                            @value={{block.fence.code}}
                            disabled={{block.fence.incomplete}}
                          />
                        </b.Actions>
                      </b.Header>
                      <b.Content>
                        {{#each (highlightedCode block.fence.code block.fence.language) as |line|}}
                          <b.Line @code={{line}} />
                        {{/each}}
                      </b.Content>
                    </CodeBlock>
                  {{else}}
                    <p>
                      {{~#each block.inline as |part|~}}
                        {{~#if part.isCode~}}
                          <code class="rounded-sm bg-muted px-1 py-0.5 font-mono text-[0.9em]">
                            {{~part.text~}}
                          </code>
                        {{~else~}}
                          {{part.text}}
                        {{~/if~}}
                      {{~/each~}}
                    </p>
                  {{/if}}
                {{/each}}
              </div>
            </m.Content>
          </Message>
        {{/if}}
      {{/each}}
      {{#unless this.busy}}
        <Button @variant="outline" @size="sm" class="mt-auto self-start" {{on "click" this.replay}}>
          Replay
        </Button>
      {{/unless}}
    </div>
  </template>
}
