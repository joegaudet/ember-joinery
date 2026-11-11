import { hash } from '@ember/helper'
import { Card } from '@ember-joinery/ember'
import { Carousel } from '@ember-joinery/carousel'

const slides = Array.from({ length: 5 }, (_, index) => index + 1)

<template>
  {{! Named (aria-label), which upstream's isn't: a page with several carousels needs each named. }}
  <Carousel
    @opts={{hash align="start"}}
    class="w-full max-w-[12rem] sm:max-w-xs md:max-w-sm"
    aria-label="Numbers, two or three at a time"
    as |c|
  >
    <c.Content>
      {{#each slides as |number|}}
        <c.Item class="basis-1/2 lg:basis-1/3">
          <div class="p-1">
            <Card as |card|>
              <card.Content class="flex aspect-square items-center justify-center p-6">
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
