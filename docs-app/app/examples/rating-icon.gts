import { Heart } from 'lucide'
import { Rating } from '@ember-joinery/ember'

<template>
  {{! Joinery's own: any lucide icon in place of the star, and names for its items to match. }}
  <Rating
    @icon={{Heart}}
    @max={{3}}
    @defaultValue={{2}}
    @itemLabel={{(heartLabel)}}
    aria-label="How much do you like it?"
  />
</template>

function heartLabel() {
  return (value: number) => `${value} heart${value === 1 ? '' : 's'}`
}
