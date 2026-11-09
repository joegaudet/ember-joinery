import { Toggle } from '@ember-joinery/primitives/toggle'

<template>
  {{! The primitive, unstyled but for the classes here: data-state="on" while it is pressed. }}
  <Toggle
    class="inline-flex h-8 items-center gap-2 rounded-md border border-input px-3 text-sm data-[state=on]:bg-primary data-[state=on]:text-primary-foreground"
    as |pressed|
  >
    Notifications
    <span aria-hidden="true">{{if pressed "on" "off"}}</span>
  </Toggle>
</template>
