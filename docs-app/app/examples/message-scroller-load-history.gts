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
  MessageScrollerProvider,
  Tooltip,
  toast,
} from '@ember-joinery/ember'
import { createChat, getMessageText, type ChatMessage } from './chat/scripted-chat.ts'

const chat = createChat()
  .user('Can you summarize the incident channel?')
  .assistant(
    'The first alert was a delayed export job. It started backing up around 09:42 UTC and triggered the warning once the retry queue crossed the threshold.\n\nNo customer-facing checkout paths were affected, but exports for larger workspaces were running about 12 minutes behind.',
  )
  .user('Was checkout affected?')
  .assistant(
    'No checkout errors were reported. Payment authorization, order creation, and confirmation emails stayed inside their normal latency bands.\n\nThe only elevated metric was export queue depth, which maps to analytics downloads instead of checkout.',
  )
  .user('What changed in the last deploy?')
  .assistant(
    'Only the export queue worker changed. The deploy moved large CSV jobs onto the shared retry policy, which made each failed attempt hold a worker slot longer than before.\n\nThe app deploy did not include checkout, pricing, or billing API changes.',
  )
  .user('Do we need to roll back?')
  .assistant(
    'Not yet. Queue depth is recovering after we reduced retry concurrency, and the oldest pending job is now under five minutes old.\n\nKeep rollback ready if the queue starts climbing again, but the current trend points toward recovery.',
  )
  .user('Keep watching for customer-visible issues.')
  .assistant(
    'I will watch the queue and support tags for another 15 minutes. I am tracking export failures, delayed download requests, and any support thread that mentions missing reports.\n\nIf those stay quiet through the next batch window, we can close this as an internal degradation.',
  )

const history = chat.get()
const INITIAL_VISIBLE_COUNT = 5

const isUser = (message: ChatMessage) => message.role === 'user'

const paragraphs = (message: ChatMessage) =>
  getMessageText(message)
    .split(/\n\s*\n/)
    .map(paragraph => paragraph.trim())
    .filter(Boolean)

export default class MessageScrollerLoadHistory extends Component {
  // Upstream re-mounts the scroller with a new key on reset.
  @tracked demoKey = 0
  @tracked visibleCount = INITIAL_VISIBLE_COUNT

  get visibleMessages(): ChatMessage[] {
    return history.slice(-this.visibleCount)
  }

  get canLoadHistory(): boolean {
    return this.visibleCount < history.length
  }

  get isInitial(): boolean {
    return this.visibleCount === INITIAL_VISIBLE_COUNT
  }

  reset = () => {
    this.visibleCount = INITIAL_VISIBLE_COUNT
    this.demoKey += 1
  }

  loadHistory = () => {
    this.visibleCount = history.length
    toast('History loaded', {
      description: 'Scroll up to see earlier messages.',
    })
  }

  <template>
    <MessageScrollerProvider as |s|>
      <div class="relative flex flex-col gap-4">
        <Card class="mx-auto h-140 w-full max-w-sm gap-0" as |card|>
          <card.Header class="gap-1 border-b">
            <card.Title>Load History</card.Title>
            <card.Description>
              Prepended messages keep your place.
            </card.Description>
            <card.Action>
              <Tooltip as |t|>
                <Button
                  type="button"
                  @variant="outline"
                  @size="icon"
                  aria-label="Reset loaded messages"
                  disabled={{this.isInitial}}
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
            {{#each (array this.demoKey)}}
              <s.Root>
                <s.Viewport>
                  <s.Content class="p-(--card-spacing)">
                    {{#each this.visibleMessages key="id" as |message|}}
                      <s.Item @messageId={{message.id}}>
                        <Message @align={{if (isUser message) "end" "start"}} as |m|>
                          <m.Content>
                            <Bubble @variant={{if (isUser message) "muted" "ghost"}} as |b|>
                              <b.Content class="space-y-2">
                                {{#each (paragraphs message) as |paragraph|}}
                                  <p class="whitespace-pre-wrap">{{paragraph}}</p>
                                {{/each}}
                              </b.Content>
                            </Bubble>
                          </m.Content>
                        </Message>
                      </s.Item>
                    {{/each}}
                    <s.Item @scrollAnchor={{false}}>
                      <Marker @variant="separator" as |mk|>
                        <mk.Content>End of Conversation</mk.Content>
                      </Marker>
                    </s.Item>
                  </s.Content>
                </s.Viewport>
                <s.Button />
              </s.Root>
            {{/each}}
          </card.Content>
          <card.Footer class="flex flex-col items-center gap-2 border-t">
            <Button
              type="button"
              disabled={{if this.canLoadHistory false true}}
              class="w-full"
              @variant="secondary"
              {{on "click" this.loadHistory}}
            >
              {{if this.canLoadHistory "Load History" "History Loaded"}}
            </Button>
            <p class="text-xs text-muted-foreground">
              Restore earlier messages while keeping your place.
            </p>
          </card.Footer>
        </Card>
        <div class="mx-auto max-w-sm px-0.5 text-center text-xs text-balance text-muted-foreground">
          Click Load History to load the entire conversation
        </div>
      </div>
    </MessageScrollerProvider>
  </template>
}
