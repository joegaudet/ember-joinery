# @ember-joinery/carousel

shadcn/ui's [Carousel](https://ui.shadcn.com/docs/components/radix/carousel) for Ember, an
opt-in add-on to [Joinery](https://joegaudet.com/ember-joinery/): slides with motion, swipe and
keyboard control, on [Embla Carousel](https://www.embla-carousel.com/)'s framework-agnostic
core.

```bash
npm install @ember-joinery/carousel @ember-joinery/ember
```

It ships no CSS of its own: `@ember-joinery/ember`'s `joinery.css` (or any of its styles)
styles its parts, as it does every Joinery component.

```gts
import { hash } from '@ember/helper'
import { Carousel } from '@ember-joinery/carousel'

<template>
  <Carousel @opts={{hash align="start" loop=true}} aria-label="Photos" as |c|>
    <c.Content>
      <c.Item class="basis-1/3">…</c.Item>
      <c.Item class="basis-1/3">…</c.Item>
      <c.Item class="basis-1/3">…</c.Item>
    </c.Content>
    <c.Previous />
    <c.Next />
  </Carousel>
</template>
```

`@orientation`, `@opts`, `@plugins` (`embla-carousel-autoplay` and the rest) and `@setApi` are
upstream's. The carousel takes its direction from the nearest `dir`, the arrow keys move between
the slides (flipped right to left), and each slide is named by its place. `{{embla}}` is the
headless part, for a carousel of your own markup.

Its harness, `CarouselHarness`, is in `@ember-joinery/carousel/test-support`, and `settled()`
waits for a carousel to come to rest, so tests read the slides where they stop.

Full documentation: the Carousel page of the guide at
**https://joegaudet.com/ember-joinery/guide/**. Design and API ported from
[shadcn/ui](https://ui.shadcn.com/) (MIT).
