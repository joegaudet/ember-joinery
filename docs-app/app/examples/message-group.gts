import { Avatar, Bubble, Message, MessageGroup } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-6 py-12">
    <MessageGroup>
      <Message as |m|>
        <m.Avatar />
        <m.Content>
          <Bubble @variant="muted" as |b|>
            <b.Content>I checked the registry addresses.</b.Content>
          </Bubble>
        </m.Content>
      </Message>
      <Message as |m|>
        <m.Avatar>
          <Avatar as |a|>
            <a.Image @src="/avatars/02.png" alt="@avatar" />
            <a.Fallback>CN</a.Fallback>
          </Avatar>
        </m.Avatar>
        <m.Content>
          <Bubble @variant="muted" as |b|>
            <b.Content>
              The component and example JSON now live under the UI registry.
            </b.Content>
          </Bubble>
        </m.Content>
      </Message>
    </MessageGroup>
  </div>
</template>
