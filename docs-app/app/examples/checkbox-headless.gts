import { Checkbox } from '@ember-joinery/primitives/checkbox'

<template>
  {{!
    The headless checkbox, styled here with utility classes alone: it brings the behaviour,
    the ARIA and data-state, and you bring the look. Its mark renders only while it is checked.
  }}
  <div class="flex items-center gap-2 text-sm">
    <Checkbox
      id="headless-terms"
      class="flex size-5 items-center justify-center rounded border border-current bg-transparent p-0 data-[state=checked]:bg-current"
      as |checkbox|
    >
      <checkbox.Indicator class="text-xs leading-none text-background">✓</checkbox.Indicator>
    </Checkbox>
    <label for="headless-terms">Accept terms and conditions</label>
  </div>
</template>
