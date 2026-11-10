import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { on } from '@ember/modifier'
import { Brain } from 'lucide'
import {
  Bubble,
  Button,
  Icon,
  Message,
  Trace,
  TraceCollapsible,
  TraceLine,
} from '@ember-joinery/ember'
import {
  ChatSession,
  createChat,
  getMessageText,
  type ChatMessage,
  type ChatPart,
} from './trace/scripted-chat.ts'

const chat = createChat()
  .user('Why is the checkout deploy so slow?')
  .assistant(({ writer }) => {
    writer.reasoning(
      'The build log shows install and compile finish in under a minute. Image optimization takes almost four, and it reruns on every deploy because the cache key includes the commit hash.',
      { delayMs: 60 },
    )
    writer.sleep(400)
    writer.text(
      'Image optimization is the bottleneck. Key its cache on the lockfile and the image directory instead of the commit hash.',
    )
  })

const initialMessages = chat.get(0)

/** A run of parts in a message: reasoning shown as a trace, or text as paragraphs. */
interface Run {
  key: string
  trace: boolean
  parts: { key: string; part: ChatPart }[]
}

function groupParts(parts: ChatPart[]): Run[] {
  const runs: Run[] = []
  parts.forEach((part, index) => {
    const trace = part.type === 'reasoning'
    if (!trace && part.type !== 'text') return
    const last = runs[runs.length - 1]
    if (last?.trace === trace) last.parts.push({ key: `${index}`, part })
    else runs.push({ key: `run-${runs.length}`, trace, parts: [{ key: `${index}`, part }] })
  })
  return runs
}

const textOf = (part: ChatPart) => ('text' in part ? part.text : '')
const isStreaming = (live: boolean, part: ChatPart) =>
  live && 'state' in part && part.state === 'streaming'

const ThinkingLine: TOC<{ Args: { running: boolean } }> = <template>
  <TraceLine @status={{if @running "running"}} as |l|>
    <l.Icon>
      <Icon @icon={{Brain}} />
    </l.Icon>
    <l.Title>{{if @running "Thinking" "Thought"}}</l.Title>
  </TraceLine>
</template>

class ThinkingTrace extends Component<{ Args: { text: string; running: boolean } }> {
  // The reader's choice once they make one, else open while it streams.
  @tracked open: boolean | undefined

  get isOpen(): boolean {
    return this.open ?? this.args.running
  }

  setOpen = (open: boolean) => (this.open = open)

  <template>
    {{#if @text}}
      <TraceCollapsible @open={{this.isOpen}} @onOpenChange={{this.setOpen}} as |c|>
        <c.Trigger>
          <ThinkingLine @running={{@running}} />
        </c.Trigger>
        <c.Content class="whitespace-pre-wrap">{{@text}}</c.Content>
      </TraceCollapsible>
    {{else}}
      <ThinkingLine @running={{@running}} />
    {{/if}}
  </template>
}

export default class TraceThinking extends Component {
  // As useChat()'s, the session ends with its component (owner: this), stopping a stream.
  session = new ChatSession(chat, { messages: initialMessages, delayMs: 20, owner: this })

  get nextMessage(): ChatMessage | null {
    return chat.next(this.session.messages)
  }

  isUser = (message: ChatMessage) => message.role === 'user'

  isLive = (message: ChatMessage) => {
    const messages = this.session.messages
    return this.session.status === 'streaming' && message === messages[messages.length - 1]
  }

  sendOrReset = () => {
    const next = this.nextMessage
    if (next) this.session.send(next)
    else this.session.setMessages(initialMessages)
  }

  <template>
    <div class="flex min-h-72 w-full max-w-sm flex-col gap-4 py-6 text-sm">
      {{#each this.session.messages key="id" as |message|}}
        {{#if (this.isUser message)}}
          <Message @align="end" as |m|>
            <m.Content>
              <Bubble @align="end" @variant="muted" as |b|>
                <b.Content>{{getMessageText message}}</b.Content>
              </Bubble>
            </m.Content>
          </Message>
        {{else}}
          <Message as |m|>
            <m.Content class="gap-4">
              {{#each (groupParts message.parts) key="key" as |run|}}
                {{#if run.trace}}
                  <Trace>
                    {{#each run.parts key="key" as |entry|}}
                      <ThinkingTrace
                        @text={{textOf entry.part}}
                        @running={{isStreaming (this.isLive message) entry.part}}
                      />
                    {{/each}}
                  </Trace>
                {{else}}
                  {{#each run.parts key="key" as |entry|}}
                    <p>{{textOf entry.part}}</p>
                  {{/each}}
                {{/if}}
              {{/each}}
            </m.Content>
          </Message>
        {{/if}}
      {{/each}}
      {{#unless this.session.busy}}
        <Button
          @variant="outline"
          @size="sm"
          class="mt-auto self-start"
          {{on "click" this.sendOrReset}}
        >
          {{if this.nextMessage "Send message" "Reset"}}
        </Button>
      {{/unless}}
    </div>
  </template>
}
