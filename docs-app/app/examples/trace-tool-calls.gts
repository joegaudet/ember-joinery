import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { on } from '@ember/modifier'
import { Terminal } from 'lucide'
import {
  Bubble,
  Button,
  Icon,
  Message,
  Trace,
  TraceCollapsible,
  TraceLine,
} from '@ember-joinery/ember'
import { CodeBlock } from '@ember-joinery/code-block'
import {
  ChatSession,
  createChat,
  getMessageText,
  type ChatMessage,
  type ChatPart,
  type ToolPart,
} from './trace/scripted-chat.ts'

const chat = createChat()
  .user('Which package managers are installed?')
  .assistant(({ writer }) => {
    writer
      .tool('runCommand', { input: { command: 'node --version' } })
      .sleep(900)
      .output({
        stdout: 'v24.18.0',
      })
    writer
      .tool('runCommand', { input: { command: 'npm --version' } })
      .sleep(900)
      .output({
        stdout: '11.6.2',
      })
    writer
      .tool('runCommand', { input: { command: 'pnpm --version' } })
      .sleep(900)
      .error('command not found: pnpm')
    writer.text('Node 24 and npm 11 are installed. pnpm is not.')
  })

const initialMessages = chat.get(0)

/** A run of parts in a message: tool calls shown as a trace, or text as paragraphs. */
interface Run {
  key: string
  trace: boolean
  parts: { key: string; part: ChatPart }[]
}

function groupParts(parts: ChatPart[]): Run[] {
  const runs: Run[] = []
  parts.forEach((part, index) => {
    const trace = part.type === 'tool'
    if (!trace && part.type !== 'text') return
    const key = part.type === 'tool' ? part.toolCallId : `${index}`
    const last = runs[runs.length - 1]
    if (last?.trace === trace) last.parts.push({ key, part })
    else runs.push({ key: `run-${runs.length}`, trace, parts: [{ key, part }] })
  })
  return runs
}

const textOf = (part: ChatPart) => ('text' in part ? part.text : '')
const toolOf = (part: ChatPart) => part as ToolPart
const isFinished = (part: ToolPart) =>
  part.state === 'output-available' || part.state === 'output-error'
const isFailed = (part: ToolPart) => part.state === 'output-error'
const isDenied = (part: ToolPart) => part.state === 'output-denied'
const resultOf = (part: ToolPart) => (isFailed(part) ? part.errorText : part.output?.stdout)

const ToolTrace: TOC<{ Args: { part: ToolPart; live: boolean } }> = <template>
  {{#if (isFinished @part)}}
    <TraceCollapsible as |c|>
      <c.Trigger>
        <TraceLine @status={{if (isFailed @part) "error"}} as |l|>
          <l.Icon>
            <Icon @icon={{Terminal}} />
          </l.Icon>
          <l.Title>{{if (isFailed @part) "Failed to run" "Ran"}} {{@part.input.command}}</l.Title>
        </TraceLine>
      </c.Trigger>
      <c.Content>
        <CodeBlock @size="sm" as |b|>
          <b.Content @code={{resultOf @part}} @wrap={{true}} class="max-h-64" />
        </CodeBlock>
      </c.Content>
    </TraceCollapsible>
  {{else if (isDenied @part)}}
    <TraceLine as |l|>
      <l.Icon>
        <Icon @icon={{Terminal}} />
      </l.Icon>
      <l.Title>Denied {{@part.input.command}}</l.Title>
    </TraceLine>
  {{else}}
    <TraceLine @status={{if @live "running" "error"}} as |l|>
      <l.Icon>
        <Icon @icon={{Terminal}} />
      </l.Icon>
      <l.Title>{{if @live "Running" "Failed to run"}} {{@part.input.command}}</l.Title>
    </TraceLine>
  {{/if}}
</template>

export default class TraceToolCalls extends Component {
  session = new ChatSession(chat, { messages: initialMessages, delayMs: 20 })

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
                      <ToolTrace @part={{toolOf entry.part}} @live={{this.isLive message}} />
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
