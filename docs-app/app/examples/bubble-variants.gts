import { Bubble } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-12 py-12">
    <Bubble as |b|>
      <b.Content>This is the default primary bubble.</b.Content>
    </Bubble>
    <Bubble @variant="secondary" @align="end" as |b|>
      <b.Content>This is the secondary variant.</b.Content>
    </Bubble>
    <Bubble @variant="muted" as |b|>
      <b.Content>
        This one is muted. It uses a lower emphasis color for the chat bubble.
      </b.Content>
      <b.Reactions role="img" aria-label="Reaction: thumbs up">
        <span>👍</span>
      </b.Reactions>
    </Bubble>
    <Bubble @variant="tinted" @align="end" as |b|>
      <b.Content>
        This one is tinted. The tint is a softer color derived from the primary color.
      </b.Content>
    </Bubble>
    <Bubble @variant="outline" as |b|>
      <b.Content>We can also use an outlined variant.</b.Content>
    </Bubble>
    <Bubble @variant="destructive" @align="end" as |b|>
      <b.Content>Or a destructive variant with a reaction.</b.Content>
      <b.Reactions role="img" aria-label="Reaction: fire">
        <span>🔥</span>
      </b.Reactions>
    </Bubble>
    <Bubble @variant="ghost" as |b|>
      <b.Content>
        {{! Upstream renders this Markdown with its site's Markdown component (Streamdown), and Joinery
            has no Markdown renderer, so here is the HTML it renders, with Streamdown's classes. }}
        <div
          data-slot="markdown"
          class="w-full min-w-0 space-y-4 overflow-hidden whitespace-normal [&>*:first-child]:mt-0 [&>*:last-child]:mb-0"
        >
          <p>Ghost bubbles work for assistant text,
            <span class="font-semibold">markdown</span>, and other content that should not be
            framed.</p>
          <p>This is perfect for assistant messages that should not have a frame and can take the
            full width of the container. You can also render
            <code class="rounded-sm bg-muted px-1 py-0.5 font-mono text-[0.9em]">code</code>
            in it.</p>
          <p>Ghost bubbles are full width and can take the full width of the container.</p>
        </div>
      </b.Content>
    </Bubble>
  </div>
</template>
