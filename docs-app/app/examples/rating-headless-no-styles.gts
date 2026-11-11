import type { TOC } from '@ember/component/template-only'
import { Rating, type RatingIconSignature } from '@ember-joinery/primitives/rating'

const Star: TOC<RatingIconSignature> = <template>
  <div class="item">
    <span class="icon">★</span>
  </div>
</template>

<template>
  {{!
    ember-primitives' "No Styles" demo: the block lays the rating out, and rating.Stars draws
    every item with a component of its own. Its only style is the layout, so the items don't
    take the whole height. The block form has no label of its own, so it is named with
    aria-label, which the demo leaves off.
  }}
  <Rating aria-label="Rate it" as |rating|>
    {{rating.value}}
    of
    {{rating.total}}<br />
    <rating.Stars @icon={{Star}} class="flex gap-4" />
  </Rating>
</template>
