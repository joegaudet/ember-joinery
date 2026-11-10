import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { array } from '@ember/helper'
import { on } from '@ember/modifier'
import { RotateCw } from 'lucide'
import {
  Bubble,
  Button,
  Card,
  Icon,
  Marker,
  Message,
  MessageScrollerItem,
  MessageScrollerProvider,
  Tooltip,
  type BubbleVariant,
} from '@ember-joinery/ember'

const currentUser = 'Grace'

type GroupChatItem =
  | {
      id: string
      type: 'event'
      text: string
      scrollAnchor?: boolean
    }
  | {
      id: string
      type: 'message'
      sender: string
      role: 'assistant' | 'participant'
      text: string
      scrollAnchor?: boolean
    }

const initialItems: GroupChatItem[] = [
  {
    id: 'group-1',
    type: 'message',
    sender: 'Grace',
    role: 'participant',
    text: '@mary, the astrophage line keeps matching Venus energy output. Can you check my math?',
  },
  {
    id: 'group-2',
    type: 'message',
    sender: 'Mary (Agent)',
    role: 'assistant',
    text: 'Yes. Confirmed. The curve points to a microorganism harvesting stellar energy and breeding near carbon dioxide. If @rocky agrees, this is the clue we need.',
  },
  {
    id: 'group-3',
    type: 'message',
    sender: 'Grace',
    role: 'participant',
    text: 'ping @rocky',
    scrollAnchor: true,
  },
]

const rockyMarker: GroupChatItem = {
  id: 'group-4',
  type: 'event',
  text: 'Rocky has joined the chat',
  scrollAnchor: true,
}

const rockyMessage: GroupChatItem = {
  id: 'group-5',
  type: 'message',
  sender: 'Rocky',
  role: 'participant',
  text: 'Amaze. Astrophage eats light, makes heat, goes to carbon dioxide. Rocky has fuel model. Grace is smart.',
}

const isMessage = (item: GroupChatItem) => item.type === 'message'
const isCurrentUser = (item: GroupChatItem) =>
  item.type === 'message' && item.sender === currentUser
const senderOf = (item: GroupChatItem) => (item.type === 'message' ? item.sender : '')

function variantOf(item: GroupChatItem): BubbleVariant {
  if (isCurrentUser(item)) return 'muted'
  return item.type === 'message' && item.role === 'assistant' ? 'ghost' : 'tinted'
}

export default class MessageScrollerGroupChat extends Component {
  // Upstream re-mounts the scroller with a new key on reset.
  @tracked demoKey = 0
  @tracked rockyTurn: 'idle' | 'marker' | 'message' = 'idle'

  get items(): GroupChatItem[] {
    if (this.rockyTurn === 'message') return [...initialItems, rockyMarker, rockyMessage]
    if (this.rockyTurn === 'marker') return [...initialItems, rockyMarker]
    return initialItems
  }

  get buttonLabel(): string {
    return this.rockyTurn === 'idle' ? 'Add Rocky' : 'Send Message as Rocky'
  }

  get isComplete(): boolean {
    return this.rockyTurn === 'message'
  }

  get isIdle(): boolean {
    return this.rockyTurn === 'idle'
  }

  reset = () => {
    this.rockyTurn = 'idle'
    this.demoKey += 1
  }

  next = () => {
    this.rockyTurn = this.rockyTurn === 'idle' ? 'marker' : 'message'
  }

  <template>
    <MessageScrollerProvider>
      <div class="relative flex flex-col gap-4">
        <Card class="mx-auto h-140 w-full max-w-sm gap-0" as |card|>
          <card.Header class="gap-1 border-b">
            <card.Title>Group Chat</card.Title>
            <card.Description>
              A group chat with several participants and an assistant. The Marker is marked as a
              turn.
            </card.Description>
            <card.Action>
              <Tooltip as |t|>
                <Button
                  type="button"
                  @variant="outline"
                  @size="icon"
                  aria-label="Reset conversation"
                  disabled={{this.isIdle}}
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
          <card.Content class="min-h-0 flex-1 p-0">
            <MessageScrollerProvider as |s|>
              {{#each (array this.demoKey)}}
                <s.Root>
                  <s.Viewport>
                    <s.Content class="p-(--card-spacing)">
                      {{#each this.items key="id" as |item|}}
                        {{#if (isMessage item)}}
                          <MessageScrollerItem
                            @messageId={{item.id}}
                            @scrollAnchor={{item.scrollAnchor}}
                          >
                            <Message @align={{if (isCurrentUser item) "end" "start"}} as |m|>
                              <m.Content>
                                {{#unless (isCurrentUser item)}}
                                  <m.Header>{{senderOf item}}</m.Header>
                                {{/unless}}
                                <Bubble @variant={{variantOf item}} as |b|>
                                  <b.Content>{{item.text}}</b.Content>
                                </Bubble>
                              </m.Content>
                            </Message>
                          </MessageScrollerItem>
                        {{else}}
                          <MessageScrollerItem @scrollAnchor={{item.scrollAnchor}}>
                            <Marker @variant="separator" as |mk|>
                              <mk.Content>{{item.text}}</mk.Content>
                            </Marker>
                          </MessageScrollerItem>
                        {{/if}}
                      {{/each}}
                    </s.Content>
                  </s.Viewport>
                  <s.Button />
                </s.Root>
              {{/each}}
            </MessageScrollerProvider>
          </card.Content>
          <card.Footer class="flex flex-col items-center gap-2 border-t">
            <Button
              type="button"
              disabled={{this.isComplete}}
              class="w-full"
              @variant="secondary"
              {{on "click" this.next}}
            >
              {{this.buttonLabel}}
            </Button>
            <p class="text-xs text-muted-foreground">
              {{#if this.isIdle}}
                This will create a marker and make it the anchor
              {{else}}
                Now send Rocky's reply into the conversation
              {{/if}}
            </p>
          </card.Footer>
        </Card>
        <div class="mx-auto max-w-sm px-0.5 text-center text-xs text-balance text-muted-foreground">
          When a user joins, a marker is created. scrollAnchor on the marker marks it as the next
          turn
        </div>
      </div>
    </MessageScrollerProvider>
  </template>
}
