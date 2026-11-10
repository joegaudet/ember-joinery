import Component from '@glimmer/component'
import { registerDestructor } from '@ember/destroyable'
import { on } from '@ember/modifier'
import type Owner from '@ember/owner'
import {
  ArrowUp,
  Globe,
  Image as ImageIcon,
  MessageCircleDashed,
  Paperclip,
  Plus,
  RotateCw,
  Telescope,
} from 'lucide'
import {
  Button,
  Card,
  DropdownMenu,
  Empty,
  Icon,
  InputGroup,
  MessageScrollerProvider,
  Tooltip,
} from '@ember-joinery/ember'
import MessageAnimated from './chat/message-animated.gts'
import { createChat, getMessageText, type ChatMessage } from './chat/scripted-chat.ts'

const chat = createChat()
  .user(
    "I'm building a chat for our app and the scroll behavior is driving me nuts. Every time the AI streams a reply, the whole thread jumps around.",
  )
  .sleep(1000)
  .assistant(
    "That's the classic streaming scroll problem. Wrap your message list in `MessageScroller` and turn on `autoScroll` — the viewport pins to the bottom as tokens arrive, so users always see the latest text land in place.\n\nThe important part: it only auto-scrolls while the reader is already at the bottom. The moment they scroll up to read something earlier, auto-scroll backs off and their position is preserved. You get smooth streaming without fighting the user's intent.",
  )
  .user(
    'Okay, but when someone sends a new message the view still feels jarring — like the whole conversation reloads from the top.',
  )
  .sleep(1000)
  .assistant(
    "MessageScrollerItem fixes that with turn anchoring. Set `scrollAnchor` on the turn that should settle near the top instead of blindly snapping to the document bottom.\n\nIt also leaves a small peek of the previous exchange visible above the anchor, so context isn't lost. The reply starts in view without that disorienting jump you get from a plain overflow container.",
  )
  .user(
    "And if they've scrolled up to re-read an older answer? I don't want to yank them back down.",
  )
  .sleep(1000)
  .assistant(
    "You won't. Auto-scroll only runs when the viewport is already pinned to the bottom, so scrolling up is a deliberate opt-out — their place in the thread stays put even as new tokens keep arriving below.\n\nWhen there is content they haven't seen yet, `MessageScrollerButton` appears at the bottom of the viewport. One tap jumps them back to the newest message and re-engages auto-scroll. Same pattern as Slack or iMessage: quiet when you're caught up, helpful when you're not.",
  )
  .user('Last one — does this work with assistive tech?')
  .sleep(1000)
  .assistant(
    '`MessageScrollerContent` sets `role="log"` and `aria-relevant="additions"` by default, so screen readers announce new messages as they stream in.\n\nThe scroll button is a real `<button>` with an sr-only label, and it\'s removed from the tab order when you\'re already at the bottom — no ghost focus stops.',
  )
const initialMessages = chat.get(0)

const isUser = (message: ChatMessage) => message.role === 'user'

export default class MessageScrollerStreaming extends Component {
  session = chat.session({ messages: initialMessages, delayMs: 20 })

  constructor(owner: Owner, args: object) {
    super(owner, args)
    registerDestructor(this, this.session.stop)
  }

  get cannotSend(): boolean {
    return !this.session.nextMessage || this.session.isBusy
  }

  send = (event: SubmitEvent) => {
    event.preventDefault()
    const next = this.session.nextMessage
    if (!next || this.session.isBusy) return
    this.session.sendMessage(next)
  }

  reset = () => {
    this.session.setMessages(initialMessages)
  }

  get cannotReset(): boolean {
    return this.session.messages.length === 0 || this.session.isBusy
  }

  <template>
    <MessageScrollerProvider @autoScroll={{true}} as |s|>
      <div class="relative flex flex-col gap-4">
        <Card class="mx-auto h-140 w-full max-w-sm gap-0" as |card|>
          <card.Header class="gap-1 border-b">
            <card.Title>Streaming Messages</card.Title>
            <card.Description>
              Auto-scroll follows the live edge of the conversation.
            </card.Description>
            <card.Action>
              <Tooltip as |t|>
                <Button
                  @variant="outline"
                  @size="icon"
                  aria-label="Reset stream"
                  disabled={{this.cannotReset}}
                  {{on "click" this.reset}}
                  {{t.trigger}}
                >
                  <Icon @icon={{RotateCw}} />
                </Button>
                <t.Content>
                  <p>Reset</p>
                </t.Content>
              </Tooltip>
            </card.Action>
          </card.Header>
          <card.Content class="flex-1 overflow-hidden p-0">
            {{#if this.session.messages.length}}
              <s.Root>
                <s.Viewport>
                  <s.Content
                    aria-busy={{if this.session.isBusy "true" "false"}}
                    class="p-(--card-spacing)"
                  >
                    {{#each this.session.messages key="id" as |message|}}
                      <MessageAnimated @message={{message}} @scrollAnchor={{isUser message}} />
                    {{/each}}
                  </s.Content>
                </s.Viewport>
                <s.Button />
              </s.Root>
            {{else}}
              <Empty class="h-full" as |e|>
                <e.Header>
                  <e.Media @variant="icon">
                    <Icon @icon={{MessageCircleDashed}} />
                  </e.Media>
                  <e.Title>Ready to Stream</e.Title>
                  <e.Description>
                    Press send to stream a scripted launch summary.
                  </e.Description>
                </e.Header>
              </Empty>
            {{/if}}
          </card.Content>
          <card.Footer class="flex-col gap-2">
            <form class="w-full" {{on "submit" this.send}}>
              <InputGroup as |g|>
                <div class="h-14 w-full px-3 py-2.5">
                  <span
                    class="line-clamp-2 opacity-60 data-[status=ready]:opacity-100"
                    data-status={{this.session.status}}
                  >
                    {{#if this.session.nextMessage}}
                      {{getMessageText this.session.nextMessage}}
                    {{else}}
                      <span class="text-muted-foreground">
                        No messages queued. Reset the stream.
                      </span>
                    {{/if}}
                  </span>
                </div>
                {{! Upstream's DropdownMenu sits inside the addon and renders no element;
                  Joinery's root is an element, so the menu goes around the addon. }}
                <DropdownMenu as |m|>
                  <g.Addon @align="block-end" class="pt-1">
                    <g.Button
                      aria-label="Add files"
                      type="button"
                      @size="icon-sm"
                      @variant="outline"
                      {{m.trigger}}
                    >
                      <Icon @icon={{Plus}} />
                    </g.Button>
                    <g.Button
                      type="submit"
                      @variant="default"
                      @size="icon-sm"
                      disabled={{this.cannotSend}}
                      class="ml-auto"
                    >
                      <Icon @icon={{ArrowUp}} />
                      <span class="sr-only">Send</span>
                    </g.Button>
                  </g.Addon>
                  <m.Content @align="start" @side="top" class="w-44">
                    <m.Item>
                      <Icon @icon={{Paperclip}} />
                      Add Photos &amp; Files
                    </m.Item>
                    <m.Separator />
                    <m.Item>
                      <Icon @icon={{ImageIcon}} />
                      Create Image
                    </m.Item>
                    <m.Item>
                      <Icon @icon={{Telescope}} />
                      Deep Research
                    </m.Item>
                    <m.Item>
                      <Icon @icon={{Globe}} />
                      Web Search
                    </m.Item>
                  </m.Content>
                </DropdownMenu>
              </InputGroup>
            </form>
          </card.Footer>
        </Card>
        <div class="px-0.5 text-center text-xs text-muted-foreground">
          Streaming is simulated. `autoScroll` is enabled.
        </div>
      </div>
    </MessageScrollerProvider>
  </template>
}
