import { Rating } from '@ember-joinery/primitives/rating'

<template>
  {{!
    The headless rating, styled here with utility classes alone: native radios, each with a
    label, in a fieldset. Its block lays it out, with a range input for quarter values.
  }}
  <Rating @step={{0.25}} @defaultValue={{2.75}} as |rating|>
    <legend class="mb-2 text-sm font-medium">Rate the film</legend>
    <div class="flex items-center gap-4">
      <rating.Range aria-label="Rate the film, in quarters" class="w-32" />
      <span class="text-sm tabular-nums">{{rating.value}} / {{rating.max}}</span>
    </div>
  </Rating>
</template>
