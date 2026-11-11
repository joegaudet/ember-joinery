import { Avatar, Bubble, BubbleGroup, Message } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-6 py-12">
    <Message as |m|>
      <m.Avatar>
        <Avatar as |a|>
          <a.Image @src="/avatars/03.png" alt="@avatar" />
          <a.Fallback>R</a.Fallback>
        </Avatar>
      </m.Avatar>
      <m.Content>
        <Bubble @variant="muted" as |b|>
          <b.Content>
            The build failed during dependency installation.
          </b.Content>
        </Bubble>
      </m.Content>
    </Message>
    <Message @align="end" as |m|>
      <m.Avatar>
        <Avatar as |a|>
          <a.Image @src="/avatars/10.png" alt="@avatar" />
          <a.Fallback>R</a.Fallback>
        </Avatar>
      </m.Avatar>
      <m.Content>
        <Bubble as |b|>
          <b.Content>Can you share the exact error?</b.Content>
        </Bubble>
      </m.Content>
    </Message>
    <Message as |m|>
      <m.Avatar>
        <Avatar as |a|>
          <a.Image @src="/avatars/03.png" alt="@avatar" />
          <a.Fallback>R</a.Fallback>
        </Avatar>
      </m.Avatar>
      <m.Content>
        <BubbleGroup>
          <Bubble @variant="muted" as |b|>
            <b.Content>Here's the error from the logs</b.Content>
          </Bubble>
          <Bubble @variant="muted" as |b|>
            <b.Content>
              Something went wrong with the build. The libraries are not installed correctly. Try
              running the build again.
            </b.Content>
          </Bubble>
        </BubbleGroup>
      </m.Content>
    </Message>
  </div>
</template>
