import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { ArrowUp, MessageCircleDashed, RotateCw } from 'lucide'
import {
  Button,
  Card,
  Empty,
  Icon,
  MessageScrollerProvider,
  ToggleGroup,
} from '@ember-joinery/ember'
import MessageAnimated from './chat/message-animated.gts'

type AnchorRole = 'user' | 'assistant'

interface ChatMessage {
  id: string
  role: AnchorRole
  text: string
}

const scriptedMessages: ChatMessage[] = [
  {
    id: 'anchor-1-user',
    role: 'user',
    text: 'Can you show me how anchoring behaves when a new prompt starts the turn?',
  },
  {
    id: 'anchor-1-assistant',
    role: 'assistant',
    text: 'Append the user prompt first, then append the assistant response. With User selected, the prompt settles near the top and the assistant response fills in below it.',
  },
  {
    id: 'anchor-2-user',
    role: 'user',
    text: 'What changes when assistant messages are the anchor?',
  },
  {
    id: 'anchor-2-assistant',
    role: 'assistant',
    text: 'Now each assistant response is the item `MessageScroller` keeps in view. This is useful when the reply is the moment you want readers to land on after each turn.',
  },
  {
    id: 'anchor-3-user',
    role: 'user',
    text: 'Can I switch roles and keep adding turns?',
  },
  {
    id: 'anchor-3-assistant',
    role: 'assistant',
    text: 'Yes. The next appended message with the selected role becomes the anchor, so you can compare user and assistant anchoring without resetting the demo.',
  },
]

export default class MessageScrollerAnchoring extends Component {
  @tracked anchorRole: AnchorRole = 'user'
  @tracked messages: ChatMessage[] = []
  @tracked messageIndex = 0

  get nextMessage(): ChatMessage | undefined {
    return scriptedMessages[this.messageIndex]
  }

  isAnchor = (message: ChatMessage) => message.role === this.anchorRole

  reset = () => {
    this.messages = []
    this.messageIndex = 0
  }

  setAnchorRole = (value: string | string[]) => {
    if (value === 'user' || value === 'assistant') {
      this.anchorRole = value
      this.messages = []
      this.messageIndex = 0
    }
  }

  send = () => {
    const next = this.nextMessage
    if (!next) return
    this.messages = [...this.messages, next]
    this.messageIndex += 1
  }

  <template>
    <div class="relative flex flex-col gap-4">
      <Card class="mx-auto h-140 w-full max-w-sm gap-0" as |card|>
        <card.Header class="border-b">
          <card.Title>Anchoring Turns</card.Title>
          <card.Description>
            Choose which role settles near the top edge.
          </card.Description>
          <card.Action>
            <Button
              type="button"
              @variant="outline"
              @size="icon"
              aria-label="Reset anchored turns"
              disabled={{if this.messages.length false true}}
              {{on "click" this.reset}}
            >
              <Icon @icon={{RotateCw}} />
            </Button>
          </card.Action>
        </card.Header>
        <card.Content class="min-h-0 flex-1 overflow-hidden p-0">
          {{#if this.messages.length}}
            <MessageScrollerProvider as |s|>
              <s.Root>
                <s.Viewport>
                  <s.Content class="p-(--card-spacing)">
                    {{#each this.messages key="id" as |message|}}
                      <MessageAnimated
                        @message={{message}}
                        @scrollAnchor={{this.isAnchor message}}
                        @userVariant="muted"
                        @assistantVariant="ghost"
                      />
                    {{/each}}
                  </s.Content>
                </s.Viewport>
                <s.Button />
              </s.Root>
            </MessageScrollerProvider>
          {{else}}
            <Empty class="h-full" as |e|>
              <e.Header>
                <e.Media @variant="icon">
                  <Icon @icon={{MessageCircleDashed}} />
                </e.Media>
                <e.Title>No anchored messages yet</e.Title>
                <e.Description>
                  Send the first message to see the selected role anchor.
                </e.Description>
              </e.Header>
            </Empty>
          {{/if}}
        </card.Content>
        <card.Footer>
          <ToggleGroup
            @type="single"
            aria-label="Select scroll anchor role"
            @value={{this.anchorRole}}
            @onValueChange={{this.setAnchorRole}}
            as |g|
          >
            <g.Item @value="user" aria-label="Anchor user messages">
              User
            </g.Item>
            <g.Item @value="assistant" aria-label="Anchor assistant messages">
              Assistant
            </g.Item>
          </ToggleGroup>
          <Button
            type="button"
            @size="icon"
            class="ml-auto"
            disabled={{if this.nextMessage false true}}
            {{on "click" this.send}}
          >
            <Icon @icon={{ArrowUp}} />
            <span class="sr-only">Send Message</span>
          </Button>
        </card.Footer>
      </Card>
      <div class="mx-auto max-w-xs px-0.5 text-center text-xs text-muted-foreground">
        Toggle the anchor role, then send messages to compare where turns settle.
      </div>
    </div>
  </template>
}
