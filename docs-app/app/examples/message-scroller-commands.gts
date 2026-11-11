import { fn } from '@ember/helper'
import {
  Bubble,
  Button,
  Card,
  DropdownMenu,
  Message,
  MessageScrollerProvider,
} from '@ember-joinery/ember'
import { createChat, getMessageText, type ChatMessage } from './chat/scripted-chat.ts'

const chat = createChat()
  .user(
    "We're seeing activation dip after workspace creation. Can you help me find the likely step?",
    { id: 'command-activation' },
  )
  .assistant(
    'The sharpest drop is between creating the workspace and inviting the first teammate.\n\nWorkspace creation is still healthy, but the invite step is where users pause. That suggests the product is asking for collaboration before the user has enough confidence in the workspace.',
  )
  .user('What should I compare before we change the onboarding flow?', {
    id: 'command-compare',
  })
  .assistant(
    'Compare three cohorts:\n\n1. Users who choose a template before inviting teammates.\n2. Users who start from a blank workspace.\n3. Users who skip invites and return within 24 hours.\n\nIf template users invite faster, the fix is probably better first-run guidance rather than a louder invite prompt.',
  )
  .user('Can you turn that into an experiment?', {
    id: 'command-experiment',
  })
  .assistant(
    'Yes. Create a variant that shows a short checklist after workspace creation:\n\n- Pick a template.\n- Add one project detail.\n- Invite a teammate when the workspace has context.\n\nMeasure first invite completion, 24-hour return rate, and whether teams create a second project.',
  )
  .user("What's the risk if we delay the invite prompt?", {
    id: 'command-risk',
  })
  .assistant(
    'The main risk is reducing team creation for accounts that already know who they want to invite.\n\nTo protect that path, keep the invite action visible in the header and only change the primary empty-state guidance. That gives confident teams a direct route without forcing uncertain users through the invite step too early.',
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

const smoothly = { align: 'start', behavior: 'smooth' } as const

<template>
  <MessageScrollerProvider @defaultScrollPosition="end" as |s|>
    <div class="relative flex flex-col gap-4">
      <Card class="mx-auto h-140 w-full max-w-sm gap-0" as |card|>
        <card.Header class="gap-1 border-b">
          <card.Title>Commands</card.Title>
          <card.Description>
            Drive the transcript from outside.
          </card.Description>
          <card.Action>
            {{! CommandMenu }}
            <DropdownMenu as |m|>
              <Button type="button" @variant="secondary" {{m.trigger}}>
                Jump to...
              </Button>
              <m.Content @align="end" @side="bottom" class="w-64">
                <m.Label>Conversations</m.Label>
                {{#each userMessages key="id" as |message|}}
                  <m.Item @onSelect={{fn s.scrollToMessage message.id smoothly}}>
                    <span class="line-clamp-1 min-w-0">
                      {{getTrimmedMessageText message}}
                    </span>
                  </m.Item>
                {{/each}}
              </m.Content>
            </DropdownMenu>
          </card.Action>
        </card.Header>
        <card.Content class="flex-1 overflow-hidden p-0">
          <s.Root>
            <s.Viewport>
              <s.Content class="p-(--card-spacing)">
                {{#each messages key="id" as |message|}}
                  <s.Item @messageId={{message.id}} @scrollAnchor={{isUser message}}>
                    <Message @align={{if (isUser message) "end" "start"}} as |msg|>
                      <msg.Content>
                        <Bubble @variant={{if (isUser message) "muted" "ghost"}} as |b|>
                          <b.Content class="space-y-2">
                            {{#each (paragraphs message) as |paragraph|}}
                              <p class="whitespace-pre-wrap">{{paragraph}}</p>
                            {{/each}}
                          </b.Content>
                        </Bubble>
                      </msg.Content>
                    </Message>
                  </s.Item>
                {{/each}}
              </s.Content>
            </s.Viewport>
            <s.Button />
          </s.Root>
        </card.Content>
      </Card>
      <div class="mx-auto max-w-sm px-0.5 text-center text-xs text-balance text-muted-foreground">
        Use the controls to jump to any message in the conversation.
      </div>
    </div>
  </MessageScrollerProvider>
</template>
