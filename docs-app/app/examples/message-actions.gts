import { Copy, RefreshCcw, ThumbsDown, ThumbsUp } from 'lucide'
import { Bubble, Button, Icon, Message } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Message as |m|>
      <m.Content>
        <Bubble @variant="muted" as |b|>
          <b.Content>
            The install failure is coming from the workspace package.
          </b.Content>
        </Bubble>
        <m.Footer>
          <Button @variant="ghost" @size="icon" aria-label="Copy" title="Copy">
            <Icon @icon={{Copy}} />
          </Button>
          <Button @variant="ghost" @size="icon" aria-label="Like" title="Like">
            <Icon @icon={{ThumbsUp}} />
          </Button>
          <Button @variant="ghost" @size="icon" aria-label="Dislike" title="Dislike">
            <Icon @icon={{ThumbsDown}} />
          </Button>
        </m.Footer>
      </m.Content>
    </Message>
    <Message @align="end" as |m|>
      <m.Content>
        <Bubble as |b|>
          <b.Content>Okay drop me a link. Taking a look...</b.Content>
        </Bubble>
        <m.Footer class="gap-2">
          <span class="font-normal text-destructive">Failed to send</span>
          <Button @variant="ghost" @size="icon-xs" title="Retry" aria-label="Retry">
            <Icon @icon={{RefreshCcw}} />
          </Button>
        </m.Footer>
      </m.Content>
    </Message>
  </div>
</template>
