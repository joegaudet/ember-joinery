import { on } from '@ember/modifier'
import { Bubble, BubbleGroup, toast } from '@ember-joinery/ember'

const forgotPassword = () => toast('You clicked forgot password')
const subscription = () => toast('You clicked help with subscription')
const somethingElse = () => toast('You clicked something else. Talk to a human.')

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Bubble @variant="muted" as |b|>
      <b.Content>How can I help you today?</b.Content>
    </Bubble>
    <BubbleGroup>
      <Bubble @variant="tinted" @align="end" as |b|>
        <b.Content @as="button" {{on "click" forgotPassword}}>
          I forgot my password
        </b.Content>
      </Bubble>
      <Bubble @variant="tinted" @align="end" as |b|>
        <b.Content @as="button" {{on "click" subscription}}>
          I need help with my subscription
        </b.Content>
      </Bubble>
      <Bubble @variant="tinted" @align="end" as |b|>
        <b.Content @as="button" {{on "click" somethingElse}}>
          Something else. Talk to a human.
        </b.Content>
      </Bubble>
    </BubbleGroup>
  </div>
</template>
