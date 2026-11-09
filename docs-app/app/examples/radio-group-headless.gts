import { RadioGroup } from '@ember-joinery/primitives/radio-group'

const DRINKS = [
  { value: 'coffee', label: 'Coffee' },
  { value: 'tea', label: 'Tea' },
  { value: 'water', label: 'Water' },
]

<template>
  {{!
    The headless radio group, styled here with utility classes alone. The group's label names
    it, and each item's mark renders only while it is chosen.
  }}
  <div class="flex flex-col gap-2 text-sm">
    <span id="headless-drink-label" class="font-medium">Drink</span>
    <RadioGroup
      @defaultValue="tea"
      aria-labelledby="headless-drink-label"
      class="flex flex-col gap-2"
      as |group|
    >
      {{#each DRINKS as |drink|}}
        <div class="flex items-center gap-2">
          <group.Item
            @value={{drink.value}}
            id="headless-{{drink.value}}"
            class="flex size-5 items-center justify-center rounded-full border border-current bg-transparent p-0"
            as |item|
          >
            <item.Indicator class="block size-2.5 rounded-full bg-current" />
          </group.Item>
          <label for="headless-{{drink.value}}">{{drink.label}}</label>
        </div>
      {{/each}}
    </RadioGroup>
  </div>
</template>
