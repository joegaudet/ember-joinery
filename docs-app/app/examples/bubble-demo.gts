import { Bubble, BubbleGroup } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Bubble @align="end" as |b|>
      <b.Content>Hey there! what's up?</b.Content>
    </Bubble>
    <BubbleGroup>
      <Bubble @variant="muted" as |b|>
        <b.Content>Hey! Want to see chat bubbles?</b.Content>
      </Bubble>
      <Bubble @variant="muted" as |b|>
        <b.Content>
          I can group messages, switch sides, and keep the whole thread easy to scan.
        </b.Content>
        <b.Reactions role="img" aria-label="Reaction: thumbs up">
          <span>👍</span>
        </b.Reactions>
      </Bubble>
    </BubbleGroup>
    <Bubble @align="end" as |b|>
      <b.Content>Sure. Hit me with your best demo.</b.Content>
    </Bubble>
    <Bubble @variant="muted" as |b|>
      <b.Content>
        Yes. You are reading a demo that is demoing itself. Very meta. Very on-brand.
      </b.Content>
      <b.Reactions role="img" aria-label="Reactions: thumbs up, fire, eyes, and 2 more">
        <span>👍</span>
        <span>🔥</span>
        <span>👀</span>
        <span>+2</span>
      </b.Reactions>
    </Bubble>
  </div>
</template>
