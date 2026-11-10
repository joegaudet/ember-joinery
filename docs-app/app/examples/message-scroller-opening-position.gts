import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { modifier } from 'ember-modifier'
import {
  Bubble,
  Card,
  Message,
  MessageScrollerProvider,
  Tabs,
  type MessageScrollerApi,
} from '@ember-joinery/ember'

type Position = 'start' | 'end' | 'last-anchor'

const messages = [
  {
    id: 'open-1',
    role: 'user',
    text: 'This is the first message the user sent in the conversation.',
  },
  {
    id: 'open-2',
    role: 'assistant',
    text: 'Workspace creation rose 8%, but first invite completion only rose 2%.',
  },
  {
    id: 'open-3',
    role: 'user',
    text: 'This is the last message the user sent in the conversation.',
  },
  {
    id: 'open-4',
    role: 'assistant',
    text: 'Start with the invite step. Teams are creating workspaces but waiting to add collaborators.\n\nRecommended follow-up:\n\n1. Compare invite drop-off by account size.\n2. Check whether users who skip invites still return within 24 hours.\n3. Review the empty-state copy on the first project screen.\n4. Segment activation by template, since template users may not need invites right away.\n\nIf that pattern holds, the next experiment should make collaboration useful earlier instead of prompting for invites harder.',
  },
]

const positions: { value: Position; label: string }[] = [
  { value: 'start', label: 'start' },
  { value: 'end', label: 'end' },
  { value: 'last-anchor', label: 'last-anchor' },
]

const isUser = (message: { role: string }) => message.role === 'user'

const paragraphs = (text: string) =>
  text
    .split(/\n\s*\n/)
    .map(paragraph => paragraph.trim())
    .filter(Boolean)

/**
 * Upstream's OpeningPositionScroller moves the transcript in a layout effect, a frame after
 * the position (or its key) changes; this modifier does the same, on the scroller's frame.
 */
const openAt = modifier<{
  Element: HTMLElement
  Args: { Positional: [MessageScrollerApi, Position, number] }
}>((_element, [scroller, position]) => {
  const frame = requestAnimationFrame(() => {
    if (position === 'start') {
      scroller.scrollToStart({ behavior: 'auto' })
      return
    }
    if (position === 'end') {
      scroller.scrollToEnd({ behavior: 'auto' })
      return
    }
    scroller.scrollToMessage('open-3', { align: 'start', behavior: 'auto', scrollMargin: 64 })
  })
  return () => cancelAnimationFrame(frame)
})

export default class MessageScrollerOpeningPosition extends Component {
  @tracked positionKey = 0
  @tracked position: Position = 'last-anchor'

  setPosition = (value: string) => {
    if (value === 'start' || value === 'end' || value === 'last-anchor') {
      this.position = value
      this.positionKey += 1
    }
  }

  <template>
    <div class="relative flex flex-col gap-4">
      <Card class="mx-auto h-140 w-full max-w-sm gap-0" as |card|>
        <card.Header class="gap-1 border-b">
          <card.Title>Opening Position</card.Title>
          <card.Description>
            Choose where a saved transcript opens.
          </card.Description>
        </card.Header>
        <card.Content class="flex-1 overflow-hidden p-0">
          <MessageScrollerProvider as |s|>
            <s.Root {{openAt s this.position this.positionKey}}>
              <s.Viewport>
                <s.Content class="p-(--card-spacing)">
                  {{#each messages key="id" as |message|}}
                    <s.Item @messageId={{message.id}} @scrollAnchor={{isUser message}}>
                      <Message @align={{if (isUser message) "end" "start"}} as |m|>
                        <m.Content>
                          <Bubble @variant={{if (isUser message) "muted" "ghost"}} as |b|>
                            <b.Content class="space-y-2">
                              {{#each (paragraphs message.text) as |paragraph|}}
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
          </MessageScrollerProvider>
        </card.Content>
        <card.Footer class="flex items-center justify-center border-t">
          <Tabs @value={{this.position}} @onValueChange={{this.setPosition}} class="w-full" as |t|>
            <t.List class="w-full">
              {{#each positions as |option|}}
                <t.Trigger @value={{option.value}}>{{option.label}}</t.Trigger>
              {{/each}}
            </t.List>
          </Tabs>
        </card.Footer>
      </Card>
      <div class="mx-auto max-w-sm px-0.5 text-center text-xs text-muted-foreground">
        Toggle the defaultScrollPosition to see where the transcript starts when you open the thread
      </div>
    </div>
  </template>
}
