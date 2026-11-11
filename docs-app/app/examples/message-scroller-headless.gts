import Component from '@glimmer/component'
import { registerDestructor } from '@ember/destroyable'
import { on } from '@ember/modifier'
import type Owner from '@ember/owner'
import { MessageScrollerProvider } from '@ember-joinery/primitives/message-scroller'
import { createChat, getMessageText, type ChatMessage } from './chat/scripted-chat.ts'

// Upstream's @shadcn/react page wires the headless parts to the AI SDK with styles of its own;
// this one wires them to a scripted chat.
const chat = createChat()
  .user('Where does the scroll behaviour live?')
  .sleep(500)
  .assistant(
    'In the headless primitive. It anchors each turn, follows a streamed reply at the live edge and keeps your place when history loads, with no styles of its own.',
  )
  .user('So the markup is mine?')
  .sleep(500)
  .assistant(
    'All of it. The parts render plain elements; style them however you like, and hide the button while it is inert.',
  )

const isUser = (message: ChatMessage) => message.role === 'user'

export default class MessageScrollerHeadless extends Component {
  session = chat.session({ messages: chat.get(2), delayMs: 30 })

  constructor(owner: Owner, args: object) {
    super(owner, args)
    registerDestructor(this, this.session.stop)
  }

  get cannotSend(): boolean {
    return !this.session.nextMessage || this.session.isBusy
  }

  send = () => {
    const next = this.session.nextMessage
    if (next) this.session.sendMessage(next)
  }

  <template>
    <div class="flex h-96 w-full max-w-sm flex-col gap-2">
      <MessageScrollerProvider @autoScroll={{true}} as |s|>
        <s.Root class="relative flex min-h-0 flex-1 flex-col overflow-hidden rounded-lg border">
          <s.Viewport class="flex flex-1 flex-col overflow-y-auto">
            <s.Content class="flex flex-col gap-4 p-4 text-sm">
              {{#each this.session.messages key="id" as |message|}}
                <s.Item @messageId={{message.id}} @scrollAnchor={{isUser message}}>
                  <div class="rounded-lg bg-muted p-3">{{getMessageText message}}</div>
                </s.Item>
              {{/each}}
            </s.Content>
          </s.Viewport>
          <s.Button
            class="absolute bottom-2 left-1/2 z-10 -translate-x-1/2 rounded-full border bg-background px-3 py-1 text-sm font-medium inert:opacity-0"
          >
            Jump to latest
          </s.Button>
        </s.Root>
      </MessageScrollerProvider>
      <button
        type="button"
        class="rounded-md border px-3 py-1.5 text-sm disabled:opacity-50"
        disabled={{this.cannotSend}}
        {{on "click" this.send}}
      >
        Send the next message
      </button>
    </div>
  </template>
}
