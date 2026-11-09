import { Rating } from '@ember-joinery/ember'

<template>
  {{!
    Joinery's own: display-only ratings, which say their rating for assistive technology
    (Rated 4 out of 5), or show it with the label block.
  }}
  <div class="flex flex-col items-start gap-4">
    <Rating @value={{4}} @interactive={{false}} @size="sm" />
    <Rating @value={{3}} @interactive={{false}}>
      <:label as |rating|>{{rating.value}} of {{rating.total}}</:label>
    </Rating>
    <Rating @value={{2}} @readonly={{true}} @size="lg" aria-label="Your rating" />
  </div>
</template>
