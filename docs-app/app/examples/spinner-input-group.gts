import { ArrowUp } from 'lucide'
import { Icon, InputGroup, Spinner } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-md flex-col gap-4">
    <InputGroup as |g|>
      <g.Input placeholder="Send a message..." disabled />
      <g.Addon @align="inline-end">
        <Spinner />
      </g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Textarea placeholder="Send a message..." disabled />
      <g.Addon @align="block-end">
        <Spinner />
        Validating...
        <g.Button class="ml-auto" @variant="default">
          <Icon @icon={{ArrowUp}} />
          <span class="sr-only">Send</span>
        </g.Button>
      </g.Addon>
    </InputGroup>
  </div>
</template>
