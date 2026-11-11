import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { ArrowUpRight, CircleAlert, CircleCheck, Globe, LoaderCircle } from 'lucide'
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
  type SourceUrlPart,
  type ToolPart,
} from './trace/scripted-chat.ts'

const chat = createChat()
  .user('Why does pnpm install fail in CI?')
  .assistant(({ writer }) => {
    writer.reasoning(
      'CI installs with a frozen lockfile, so the install stops when package.json and pnpm-lock.yaml disagree. I should check what the last commit changed, then reproduce the install.',
      { delayMs: 40 },
    )
    writer
      .tool('runCommand', { input: { command: 'pnpm --version' } })
      .sleep(700)
      .output({
        stdout: '10.18.0',
      })
    writer
      .tool('runCommand', {
        input: { command: 'git diff --stat HEAD~1 -- package.json pnpm-lock.yaml' },
      })
      .sleep(900)
      .output({
        stdout: ' package.json | 2 +-\n 1 file changed, 1 insertion(+), 1 deletion(-)',
      })
    writer
      .tool('runCommand', { input: { command: 'pnpm install --frozen-lockfile' } })
      .sleep(1200)
      .error(
        'ERR_PNPM_OUTDATED_LOCKFILE  Cannot install with "frozen-lockfile" because pnpm-lock.yaml is not up to date with package.json',
      )
    writer.sourceUrl({
      url: 'https://pnpm.io/cli/install#--frozen-lockfile',
      title: 'pnpm install | pnpm.io',
    })
    writer.sourceUrl({
      url: 'https://pnpm.io/continuous-integration',
      title: 'Continuous Integration | pnpm.io',
    })
    writer.sleep(1000)
    writer.text(
      'The last commit bumped a version in package.json without updating pnpm-lock.yaml, so the frozen install fails. Run pnpm install locally and commit the lockfile.',
    )
  })

const transcript = chat.get()
const [question] = chat.get(1)

function isRunning(streaming: boolean, state: string): boolean {
  return streaming && state === 'streaming'
}

function isThird(index: number): boolean {
  return index === 2
}

const isFinished = (part: ToolPart) =>
  part.state === 'output-available' || part.state === 'output-error'
const isFailed = (part: ToolPart) => part.state === 'output-error'
const hostname = (source: SourceUrlPart) => source.title ?? new URL(source.url).hostname

const ThinkingLine: TOC<{ Args: { running: boolean } }> = <template>
  <TraceLine @status={{if @running "running"}} as |l|>
    <l.Icon>
      {{#if @running}}
        <Icon @icon={{LoaderCircle}} class="animate-spin" />
      {{else}}
        <Icon @icon={{CircleCheck}} />
      {{/if}}
    </l.Icon>
    <l.Title>{{if @running "Thinking" "Thought for 5s"}}</l.Title>
  </TraceLine>
</template>

class ThinkingRow extends Component<{ Args: { text: string; running: boolean } }> {
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

const ToolRow: TOC<{
  Args: { part: ToolPart; streaming: boolean; defaultOpen: boolean }
}> = <template>
  {{#if (isFinished @part)}}
    <TraceCollapsible @defaultOpen={{@defaultOpen}} as |c|>
      <c.Trigger>
        <TraceLine @status={{if (isFailed @part) "error"}} as |l|>
          <l.Icon>
            <Icon @icon={{if (isFailed @part) CircleAlert CircleCheck}} />
          </l.Icon>
          <l.Title>{{if (isFailed @part) "Failed to run" "Ran"}} {{@part.input.command}}</l.Title>
        </TraceLine>
      </c.Trigger>
      <c.Content>
        {{#if (isFailed @part)}}
          <CodeBlock @size="sm" @variant="destructive" as |b|>
            <b.Content @code={{@part.errorText}} @wrap={{true}} class="max-h-64" />
          </CodeBlock>
        {{else}}
          <CodeBlock @size="sm" as |b|>
            <b.Content @code={{@part.output.stdout}} @wrap={{true}} class="max-h-64" />
          </CodeBlock>
        {{/if}}
      </c.Content>
    </TraceCollapsible>
  {{else}}
    <TraceLine @status={{if @streaming "running" "error"}} as |l|>
      <l.Icon>
        {{#if @streaming}}
          <Icon @icon={{LoaderCircle}} class="animate-spin" />
        {{else}}
          <Icon @icon={{CircleAlert}} />
        {{/if}}
      </l.Icon>
      <l.Title>{{if @streaming "Running" "Failed to run"}} {{@part.input.command}}</l.Title>
    </TraceLine>
  {{/if}}
</template>

const SourcesRow: TOC<{ Args: { sources: SourceUrlPart[]; running: boolean } }> = <template>
  <TraceCollapsible as |c|>
    <c.Trigger>
      <TraceLine @status={{if @running "running"}} as |l|>
        <l.Icon>
          {{#if @running}}
            <Icon @icon={{LoaderCircle}} class="animate-spin" />
          {{else}}
            <Icon @icon={{Globe}} />
          {{/if}}
        </l.Icon>
        <l.Title>{{if @running "Using" "Used"}} {{@sources.length}} sources</l.Title>
      </TraceLine>
    </c.Trigger>
    <c.Content>
      <Trace>
        {{#each @sources key="url" as |source|}}
          <a href={{source.url}} target="_blank" rel="noreferrer">
            <TraceLine as |l|>
              <l.Icon>
                <Icon @icon={{Globe}} />
              </l.Icon>
              <l.Title>
                {{hostname source}}
                <span class="sr-only"> (opens in a new tab)</span>
              </l.Title>
              <l.Icon>
                <Icon @icon={{ArrowUpRight}} />
              </l.Icon>
            </TraceLine>
          </a>
        {{/each}}
      </Trace>
    </c.Content>
  </TraceCollapsible>
</template>

/** One row of the trace: a reasoning part or a tool call, keyed so it keeps its state. */
interface Row {
  key: string
  reasoning?: { text: string; state: string }
  tool?: ToolPart
  index: number
}

/** What an assistant message shows: its trace rows, its sources and its text. */
interface Reply {
  rows: Row[]
  sources: SourceUrlPart[]
  text: string
  streaming: boolean
  hasTrace: boolean
}

export default class TraceDemo extends Component {
  // As useChat()'s, the session ends with its component (owner: this), stopping a stream.
  session = new ChatSession(chat, { messages: transcript, delayMs: 20, owner: this })

  replay = () => {
    this.session.setMessages([])
    this.session.send(question!)
  }

  isUser = (message: ChatMessage) => message.role === 'user'

  reply = (message: ChatMessage): Reply => {
    const messages = this.session.messages
    const streaming = this.session.busy && message === messages[messages.length - 1]
    const rows: Row[] = []
    message.parts.forEach((part, index) => {
      if (part.type === 'reasoning')
        rows.push({ key: `reasoning-${index}`, reasoning: part, index: rows.length })
      else if (part.type === 'tool')
        rows.push({ key: part.toolCallId, tool: part, index: rows.length })
    })
    const sources = message.parts.filter(part => part.type === 'source-url')
    const text = getMessageText(message)
    return { rows, sources, text, streaming, hasTrace: rows.length + sources.length > 0 }
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
          {{#let (this.reply message) as |reply|}}
            <Message as |m|>
              <m.Content class="gap-4">
                {{#if reply.hasTrace}}
                  <Trace>
                    {{#each reply.rows key="key" as |row|}}
                      {{#if row.reasoning}}
                        <ThinkingRow
                          @text={{row.reasoning.text}}
                          @running={{isRunning reply.streaming row.reasoning.state}}
                        />
                      {{else if row.tool}}
                        <ToolRow
                          @part={{row.tool}}
                          @streaming={{reply.streaming}}
                          @defaultOpen={{isThird row.index}}
                        />
                      {{/if}}
                    {{/each}}
                    {{#if reply.sources.length}}
                      <SourcesRow
                        @sources={{reply.sources}}
                        @running={{isRunning reply.streaming (if reply.text "done" "streaming")}}
                      />
                    {{/if}}
                  </Trace>
                {{/if}}
                {{#if reply.text}}
                  <p>{{reply.text}}</p>
                {{/if}}
              </m.Content>
            </Message>
          {{/let}}
        {{/if}}
      {{/each}}
      {{#unless this.session.busy}}
        <Button @variant="outline" @size="sm" class="mt-auto self-start" {{on "click" this.replay}}>
          Replay
        </Button>
      {{/unless}}
    </div>
  </template>
}
