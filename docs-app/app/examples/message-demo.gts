import { Avatar, Bubble, BubbleGroup, Marker, Message } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-6 py-12">
    <Message @align="end" as |m|>
      <m.Avatar>
        <Avatar as |a|>
          <a.Image @src="/avatars/10.png" alt="@me" />
          <a.Fallback>ME</a.Fallback>
        </Avatar>
      </m.Avatar>
      <m.Content>
        <Bubble as |b|>
          <b.Content>Deploying to prod real quick.</b.Content>
        </Bubble>
      </m.Content>
    </Message>
    <Message as |m|>
      <m.Avatar>
        <Avatar as |a|>
          <a.Image @src="/avatars/02.png" alt="@rabbit" />
          <a.Fallback>R</a.Fallback>
        </Avatar>
      </m.Avatar>
      <m.Content>
        <Bubble @variant="muted" as |b|>
          <b.Content>It's 4:55 PM. On a Friday.</b.Content>
        </Bubble>
      </m.Content>
    </Message>
    <Message @align="end" as |m|>
      <m.Avatar>
        <Avatar as |a|>
          <a.Image @src="/avatars/10.png" alt="@me" />
          <a.Fallback>ME</a.Fallback>
        </Avatar>
      </m.Avatar>
      <m.Content>
        <Bubble as |b|>
          <b.Content>It's a one-line change.</b.Content>
        </Bubble>
        <m.Footer>Delivered</m.Footer>
      </m.Content>
    </Message>
    <Message as |m|>
      <m.Avatar>
        <Avatar as |a|>
          <a.Image @src="/avatars/02.png" alt="@rabbit" />
          <a.Fallback>R</a.Fallback>
        </Avatar>
      </m.Avatar>
      <m.Content>
        <BubbleGroup>
          <Bubble @variant="muted" as |b|>
            <b.Content>
              It's always a one-line change 😭.
            </b.Content>
          </Bubble>
          <Bubble @variant="muted" as |b|>
            <b.Content>Alright, let me take a look.</b.Content>
            <b.Reactions aria-label="Reactions: thumbs up">
              <span>👍</span>
            </b.Reactions>
          </Bubble>
        </BubbleGroup>
      </m.Content>
    </Message>
    <Marker role="status" as |m|>
      <m.Content class="shimmer">
        <span class="font-medium">Oliver</span>
        is typing...
      </m.Content>
    </Marker>
  </div>
</template>
