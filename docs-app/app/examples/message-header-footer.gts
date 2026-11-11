import { Bubble, Message } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Message as |m|>
      <m.Content>
        <m.Header>Olivia</m.Header>
        <Bubble @variant="muted" as |b|>
          <b.Content>I already checked the logs.</b.Content>
        </Bubble>
      </m.Content>
    </Message>
    <Message @align="end" as |m|>
      <m.Content>
        <Bubble as |b|>
          <b.Content>
            Send the report to the team. Ping @shadcn if you need help.
          </b.Content>
        </Bubble>
        <m.Footer>
          <div>
            Read
            <span class="font-normal">Yesterday</span>
          </div>
        </m.Footer>
      </m.Content>
    </Message>
  </div>
</template>
