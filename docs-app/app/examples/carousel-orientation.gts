import { hash } from '@ember/helper'
import { Card } from '@ember-joinery/ember'
import { Carousel } from '@ember-joinery/carousel'

const slides = Array.from({ length: 5 }, (_, index) => index + 1)

<template>
  {{! Named (aria-label), which upstream's isn't: a page with several carousels needs each named. }}
  <Carousel
    @opts={{hash align="start"}}
    @orientation="vertical"
    class="w-full max-w-xs"
    aria-label="Numbers, top to bottom"
    as |c|
  >
    <c.Content class="-mt-1 h-[270px]">
      {{#each slides as |number|}}
        <c.Item class="basis-1/2 pt-1">
          <div class="p-1">
            <Card as |card|>
              <card.Content class="flex items-center justify-center p-6">
                <span class="text-3xl font-semibold">{{number}}</span>
              </card.Content>
            </Card>
          </div>
        </c.Item>
      {{/each}}
    </c.Content>
    <c.Previous />
    <c.Next />
  </Carousel>
</template>
