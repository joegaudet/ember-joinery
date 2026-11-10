import { Card, MessageScrollerProvider } from '@ember-joinery/ember'
import MessageAnimated from './chat/message-animated.gts'

const messages = Array.from({ length: 12 }, (_, index) => ({
  id: `scrollable-${index + 1}`,
  role: index % 2 === 0 ? 'user' : 'assistant',
  text:
    index % 2 === 0
      ? `Review scroll checkpoint ${index + 1}.`
      : `Checkpoint ${index + 1} is synced. The scrollable hook updates as the viewport moves.\n\nWhen the reader is at the first message, the footer should only point them down. Once they move into the middle of the transcript, it should explain that both directions are available.\n\nAt the latest message, the footer should switch again and only point them back up.`,
}))

const isUser = (message: { role: string }) => message.role === 'user'

function getScrollStatus({ start, end }: { start: boolean; end: boolean }) {
  if (start && end) {
    return 'You can scroll both ways.'
  }

  if (end) {
    return 'You are at the top. You can only scroll down.'
  }

  if (start) {
    return 'You are at the bottom. You can only scroll up.'
  }

  return 'All messages fit in the viewport.'
}

<template>
  <div class="mx-auto flex w-full max-w-sm flex-col gap-4">
    <Card class="h-140 w-full gap-0 overflow-hidden" as |card|>
      <card.Header class="gap-1 border-b">
        <card.Title>Scroll Status</card.Title>
        <card.Description>
          Where the reader can go scroll to based on current scroll position.
        </card.Description>
      </card.Header>
      <MessageScrollerProvider @defaultScrollPosition="start" as |s|>
        <card.Content class="flex-1 overflow-hidden p-0">
          <s.Root>
            <s.Viewport>
              <s.Content class="gap-4 p-(--card-spacing)">
                {{#each messages key="id" as |message|}}
                  <MessageAnimated
                    @message={{message}}
                    @scrollAnchor={{isUser message}}
                    @userVariant="muted"
                    @assistantVariant="ghost"
                  />
                {{/each}}
              </s.Content>
            </s.Viewport>
            <s.Button />
          </s.Root>
        </card.Content>
        <card.Footer class="justify-center border-t text-center text-sm text-muted-foreground">
          {{getScrollStatus s.scrollable}}
        </card.Footer>
      </MessageScrollerProvider>
    </Card>
    <div class="px-0.5 text-center text-xs text-muted-foreground">
      Scroll the transcript to see the footer update.
    </div>
  </div>
</template>
