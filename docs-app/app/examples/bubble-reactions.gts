import { on } from '@ember/modifier'
import { Bubble, Button, toast } from '@ember-joinery/ember'

const run = () => toast.success('You clicked yes, running command...')

<template>
  <div class="flex w-full max-w-sm flex-col gap-12 py-12">
    <Bubble @variant="muted" @align="end" as |b|>
      <b.Content>
        I don't need tests, I know my code works.
      </b.Content>
      <b.Reactions @align="start" role="img" aria-label="Reactions: thumbs up, surprised">
        <span>👍</span>
        <span>😮</span>
      </b.Reactions>
    </Bubble>
    <Bubble @variant="muted" as |b|>
      <b.Content>
        Bold. Fine I'll add some tests. I'll let you know when they're done.
      </b.Content>
      <b.Reactions role="img" aria-label="Reactions: eyes, rocket, and 2 more">
        <span>👀</span>
        <span>🚀</span>
        <span>+2</span>
      </b.Reactions>
    </Bubble>
    <Bubble @variant="default" @align="end" as |b|>
      <b.Content>
        Tests passed on the first try. All 142 of them. Looking good!
      </b.Content>
      <b.Reactions
        @side="top"
        @align="start"
        role="img"
        aria-label="Reactions: party popper, clapping hands"
      >
        <span>🎉</span>
        <span>👏</span>
      </b.Reactions>
    </Bubble>
    <Bubble @variant="destructive" as |b|>
      <b.Content>Are you sure I can run this command?</b.Content>
      <b.Reactions>
        <Button @variant="ghost" @size="xs" {{on "click" run}}>
          Yes, run it
        </Button>
      </b.Reactions>
    </Bubble>
  </div>
</template>
