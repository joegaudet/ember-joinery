import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { Bubble, Card, HoverCard, Message, MessageScrollerProvider } from '@ember-joinery/ember'
import { createChat, getMessageText, type ChatMessage } from './chat/scripted-chat.ts'

const chat = createChat()
  .user('Review the incident handoff and tell me what to read first.', {
    id: 'vis-brief',
  })
  .assistant(
    'Start with the summary and the impact section. The regression affected the upload queue, but the recovery path completed for every queued job.',
  )
  .user('What was the customer impact?', {
    id: 'vis-impact',
  })
  .assistant(
    'Impact was limited to delayed processing.\n\nNo records were dropped, and the reconciliation worker confirmed each retry batch. Support saw confusion from two customers, but there were no checkout or billing errors.',
  )
  .user('What actions are open?', {
    id: 'vis-actions',
  })
  .assistant(
    'Keep the retry window enabled until the next deploy, then add a queue-depth alert as the long-term fix.\n\nThe alert should fire on sustained queue growth, not a single short spike.',
  )
  .user('Give me the follow-up checklist.', {
    id: 'vis-checklist',
  })
  .assistant(
    'After that, compare the queue recovery graph with the deploy timeline so the handoff shows exactly when processing returned to baseline. That makes it easier for support and engineering to answer the same customer questions without re-reading the whole incident thread.\n\nI would also add a short owner note beside each follow-up item. The checklist is small, but ownership keeps the retry-window decision, alert tuning, and support macro from drifting into separate follow-up conversations.\n\nKeep the retry window enabled until the next deploy, then add a queue-depth alert as the long-term fix.\n\nThe alert should fire on sustained queue growth, not a single short spike.',
  )

const messages = chat.get()
const userMessages = messages.filter(message => message.role === 'user')

const isUser = (message: ChatMessage) => message.role === 'user'

const paragraphs = (message: ChatMessage) =>
  getMessageText(message)
    .split(/\n\s*\n/)
    .map(paragraph => paragraph.trim())
    .filter(Boolean)

function getTrimmedMessageText(message: ChatMessage) {
  const text = getMessageText(message)
  return text.length > 42 ? `${text.slice(0, 39)}...` : text
}

const isCurrent = (message: ChatMessage, currentAnchorId: string | null) =>
  message.id === currentAnchorId

const smoothly = { align: 'start', behavior: 'smooth' } as const

<template>
  <MessageScrollerProvider @scrollMargin={{12}} as |s|>
    <div class="relative flex flex-col gap-4">
      <div class="relative mx-auto w-full max-w-sm">
        <Card class="h-140 w-full gap-0" as |card|>
          <card.Header class="gap-1 border-b">
            <card.Title>Transcript Outline</card.Title>
            <card.Description>
              Track the current anchored turn.
            </card.Description>
          </card.Header>
          <card.Content class="flex-1 overflow-hidden p-0">
            <s.Root>
              <s.Viewport>
                <s.Content class="p-(--card-spacing)">
                  {{#each messages key="id" as |message|}}
                    <s.Item @messageId={{message.id}} @scrollAnchor={{isUser message}}>
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
                </s.Content>
              </s.Viewport>
              <s.Button />
            </s.Root>
          </card.Content>
        </Card>
        <div class="absolute top-1/2 -right-12 -translate-y-1/2">
          {{! TranscriptOutline }}
          <s.Visibility as |visibility|>
            <HoverCard @openDelay={{0}} @closeDelay={{0}} as |h|>
              <button
                type="button"
                aria-label="Open transcript outline"
                class="flex h-9 w-9 flex-col items-center justify-center gap-1 rounded-md transition-colors outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
                {{h.trigger}}
              >
                {{#each userMessages key="id" as |message|}}
                  <span
                    data-current={{if
                      (isCurrent message visibility.currentAnchorId)
                      "true"
                      "false"
                    }}
                    class="h-0.5 w-4 rounded-full bg-muted-foreground/40 data-[current=true]:bg-foreground"
                  ></span>
                {{/each}}
              </button>
              <h.Content
                @align="center"
                @side="left"
                @sideOffset={{-28}}
                class="flex w-64 flex-col gap-1 rounded-2xl p-1"
              >
                {{#each userMessages key="id" as |message|}}
                  <button
                    type="button"
                    aria-current={{if (isCurrent message visibility.currentAnchorId) "location"}}
                    class="flex min-h-7 items-center rounded-xl px-2 py-1.5 text-left text-sm transition-colors outline-none hover:bg-accent hover:text-accent-foreground focus-visible:bg-accent focus-visible:text-accent-foreground aria-current:bg-accent aria-current:text-accent-foreground"
                    {{on "click" (fn s.scrollToMessage message.id smoothly)}}
                  >
                    <span class="line-clamp-1 min-w-0">
                      {{getTrimmedMessageText message}}
                    </span>
                  </button>
                {{/each}}
              </h.Content>
            </HoverCard>
          </s.Visibility>
        </div>
      </div>
      <div class="mx-auto max-w-sm px-0.5 text-center text-xs text-muted-foreground">
        Open the outline to jump between anchored turns as you read.
      </div>
    </div>
  </MessageScrollerProvider>
</template>
