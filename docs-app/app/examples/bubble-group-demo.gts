import { Bubble, BubbleGroup } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Bubble @variant="muted" as |b|>
      <b.Content>Can you tell me what's the issue?</b.Content>
    </Bubble>
    <BubbleGroup>
      <Bubble @align="end" as |b|>
        <b.Content>You tell me!</b.Content>
      </Bubble>
      <Bubble @align="end" as |b|>
        <b.Content>It worked yesterday. You broke it!</b.Content>
      </Bubble>
      <Bubble @align="end" as |b|>
        <b.Content>Find the bug and fix it.</b.Content>
        <b.Reactions aria-label="Reactions: eyes" @align="start">
          <span>👀</span>
        </b.Reactions>
      </Bubble>
    </BubbleGroup>
    <Bubble @variant="muted" as |b|>
      <b.Content>
        Want me to diff yesterday's you against today's you? It's a bit embarrassing.
      </b.Content>
    </Bubble>
  </div>
</template>
