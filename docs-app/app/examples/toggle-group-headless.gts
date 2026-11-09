import { ToggleGroup } from '@ember-joinery/primitives/toggle-group'

<template>
  {{! The primitive, unstyled but for the classes here: one alignment at a time. }}
  <ToggleGroup
    @type="single"
    @defaultValue="left"
    aria-label="Text alignment"
    class="inline-flex rounded-md border border-input p-0.5"
    as |g|
  >
    <g.Item
      @value="left"
      class="h-7 rounded px-3 text-sm data-[state=on]:bg-muted data-[state=on]:font-medium"
    >Left</g.Item>
    <g.Item
      @value="center"
      class="h-7 rounded px-3 text-sm data-[state=on]:bg-muted data-[state=on]:font-medium"
    >Center</g.Item>
    <g.Item
      @value="right"
      class="h-7 rounded px-3 text-sm data-[state=on]:bg-muted data-[state=on]:font-medium"
    >Right</g.Item>
  </ToggleGroup>
</template>
