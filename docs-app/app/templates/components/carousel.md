# Carousel

A carousel with motion and swipe built using Embla.

<Example @name="carousel-demo" @title="Carousel" />

## About

The carousel component is built using the [Embla Carousel](https://www.embla-carousel.com/)
library: its framework-agnostic core, `embla-carousel`, which upstream reaches through
`embla-carousel-react`.

## Installation

Carousel is an add-on, so it comes in its own package, with Embla as a dependency:

```bash
pnpm add @ember-joinery/carousel @ember-joinery/ember
```

It ships no CSS of its own: Joinery's `joinery.css` (or any of its styles) styles its parts, as
it does every component. Import that once (see
[Installation](/getting-started/installation.md)), then the component where you use it:

```gts
import { Carousel } from '@ember-joinery/carousel'
```

## Usage

```gts
<Carousel as |c|>
  <c.Content>
    <c.Item>...</c.Item>
    <c.Item>...</c.Item>
    <c.Item>...</c.Item>
  </c.Content>
  <c.Previous />
  <c.Next />
</Carousel>
```

## Composition

Use the following composition to build a `Carousel`. Its parts are yielded (`c.Content`), so
they need no import of their own:

```text
Carousel
├── c.Content
│   ├── c.Item
│   └── c.Item
├── c.Previous
└── c.Next
```

## Sizes

To set the size of the items, you can use the `basis` utility class on the `c.Item`.

<Example @name="carousel-size" @title="Sizes" />

```gts
{{! 33% of the carousel width. }}
<Carousel as |c|>
  <c.Content>
    <c.Item class="basis-1/3">...</c.Item>
    <c.Item class="basis-1/3">...</c.Item>
    <c.Item class="basis-1/3">...</c.Item>
  </c.Content>
</Carousel>
```

```gts
{{! 50% on small screens and 33% on larger screens. }}
<Carousel as |c|>
  <c.Content>
    <c.Item class="md:basis-1/2 lg:basis-1/3">...</c.Item>
    <c.Item class="md:basis-1/2 lg:basis-1/3">...</c.Item>
    <c.Item class="md:basis-1/2 lg:basis-1/3">...</c.Item>
  </c.Content>
</Carousel>
```

Those are Tailwind's classes, as upstream's are; without Tailwind, set `flex-basis` on the
items in your own CSS.

## Spacing

To set the spacing between the items, we use a `pl-[VALUE]` utility on the `c.Item` and a
negative `-ml-[VALUE]` on the `c.Content`. The class on `c.Content` goes on the row of slides
inside it, as upstream's `className` does. Joinery's own spacing is logical (`-ms-4` and `ps-4`),
so it flips right to left; use `-ms-` and `ps-` for yours to do the same.

<Example @name="carousel-spacing" @title="Spacing" />

```gts
<Carousel as |c|>
  <c.Content class="-ml-4">
    <c.Item class="pl-4">...</c.Item>
    <c.Item class="pl-4">...</c.Item>
    <c.Item class="pl-4">...</c.Item>
  </c.Content>
</Carousel>
```

```gts
<Carousel as |c|>
  <c.Content class="-ml-2 md:-ml-4">
    <c.Item class="pl-2 md:pl-4">...</c.Item>
    <c.Item class="pl-2 md:pl-4">...</c.Item>
    <c.Item class="pl-2 md:pl-4">...</c.Item>
  </c.Content>
</Carousel>
```

## Orientation

Use the `@orientation` argument to set the orientation of the carousel. A vertical carousel
needs a height: put it on `c.Content`.

<Example @name="carousel-orientation" @title="Orientation" />

```gts
<Carousel @orientation="vertical" as |c|>
  {{! or "horizontal", the default }}
  <c.Content>
    <c.Item>...</c.Item>
    <c.Item>...</c.Item>
    <c.Item>...</c.Item>
  </c.Content>
</Carousel>
```

## Options

You can pass options to the carousel using the `@opts` argument. See the
[Embla Carousel docs](https://www.embla-carousel.com/api/options/) for more information.

```gts
import { hash } from '@ember/helper'

<template>
  <Carousel @opts={{hash align="start" loop=true}} as |c|>
    <c.Content>
      <c.Item>...</c.Item>
      <c.Item>...</c.Item>
      <c.Item>...</c.Item>
    </c.Content>
  </Carousel>
</template>
```

When the options change, the carousel reinitializes and keeps its place, as upstream's does.

## API

Use the `@setApi` argument to get an instance of the carousel API. It is called once, with
Embla's API, after the carousel renders, so it can set tracked state.

<Example @name="carousel-api" @title="API" />

```gts
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Carousel, type CarouselApi } from '@ember-joinery/carousel'

export default class Example extends Component {
  @tracked current = 0
  @tracked count = 0

  setApi = (api: CarouselApi) => {
    this.count = api.scrollSnapList().length
    this.current = api.selectedScrollSnap() + 1

    api.on('select', () => {
      this.current = api.selectedScrollSnap() + 1
    })
  }

  <template>
    <Carousel @setApi={{this.setApi}} as |c|>
      <c.Content>
        <c.Item>...</c.Item>
        <c.Item>...</c.Item>
        <c.Item>...</c.Item>
      </c.Content>
    </Carousel>
  </template>
}
```

`Carousel` also yields what upstream's `useCarousel()` returns, for parts of your own:
`c.api`, `c.canScrollPrev`, `c.canScrollNext`, `c.scrollPrev`, `c.scrollNext`, `c.scrollTo`
and `c.orientation`.

```gts
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'

<template>
  <Carousel as |c|>
    <c.Content>…</c.Content>
    <button type="button" {{on "click" (fn c.scrollTo 0)}}>Back to the start</button>
  </Carousel>
</template>
```

## Events

You can listen to events using the API instance from `@setApi`.

```gts
import Component from '@glimmer/component'
import { Carousel, type CarouselApi } from '@ember-joinery/carousel'

export default class Example extends Component {
  setApi = (api: CarouselApi) => {
    api.on('select', () => {
      // Do something on select.
    })
  }

  <template>
    <Carousel @setApi={{this.setApi}} as |c|>
      <c.Content>
        <c.Item>...</c.Item>
        <c.Item>...</c.Item>
        <c.Item>...</c.Item>
      </c.Content>
    </Carousel>
  </template>
}
```

See the [Embla Carousel docs](https://www.embla-carousel.com/api/events/) for more information on
using events.

## Plugins

You can use the `@plugins` argument to add plugins to the carousel.

```gts
import Component from '@glimmer/component'
import Autoplay from 'embla-carousel-autoplay'

export default class Example extends Component {
  plugins = [Autoplay({ delay: 2000 })]

  <template>
    <Carousel @plugins={{this.plugins}} as |c|>
      {{! ... }}
    </Carousel>
  </template>
}
```

A plugin belongs to one carousel, so make it per component, as upstream's `useRef` does, not
once for the module. Embla's plugins are framework-agnostic: `pnpm add embla-carousel-autoplay`.

<Example @name="carousel-plugin" @title="Plugins" />

## RTL

Joinery's styles use logical properties, so a carousel lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the previous button moves
to the right, the next to the left, and their arrows turn round.

<Example @name="carousel-rtl" @title="RTL" @dir="rtl" />

Upstream asks you to set Embla's `direction` option to match the text direction. Joinery's
carousel takes it from the nearest `dir`, and follows it when it changes, so there is nothing to
set. To force one, pass it in `@opts`:

```gts
<Carousel @opts={{hash direction="rtl"}} dir="rtl" as |c|>
  <c.Content>
    <c.Item>...</c.Item>
    <c.Item>...</c.Item>
    <c.Item>...</c.Item>
  </c.Content>
  <c.Previous />
  <c.Next />
</Carousel>
```

The arrow keys follow the direction too: right to left, the left arrow goes to the next slide.

## API Reference

See the [Embla Carousel docs](https://www.embla-carousel.com/api/) for more information on
options, the API and plugins.

### Carousel

| Argument       | Type                                       | Default        | What it does                                                        |
| -------------- | ------------------------------------------ | -------------- | ------------------------------------------------------------------- |
| `@orientation` | `"horizontal" \| "vertical"`               | `"horizontal"` | Which way the slides run, and so Embla's axis                       |
| `@opts`        | `CarouselOptions` (Embla's options)        |                | Embla's options; without `direction`, the nearest `dir`'s           |
| `@plugins`     | `CarouselPlugin[]` (Embla plugins)         |                | Embla plugins, such as `Autoplay()`                                 |
| `@setApi`      | `(api: CarouselApi) => void`               |                | Called with Embla's API once the carousel exists                    |
| `@slideLabel`  | `(index: number, count: number) => string` | `"2 of 5"`     | Each slide's accessible name, from its place (from 1) and the count |
| `@as`          | tag name                                   | `div`          | The tag to render                                                   |
| `@name`        | `string`                                   |                | Its name, for `CarouselHarness` (`data-test-jn-name`)               |

It takes attributes on its element, `class` and `aria-label` included. `CarouselApi`,
`CarouselOptions` and `CarouselPlugin` are Embla's own types, exported under upstream's names.

### The parts

`Carousel` yields its parts and its state. Each part takes attributes, `class` included.

| Part         | Arguments                                       | What it is                                                                  |
| ------------ | ----------------------------------------------- | --------------------------------------------------------------------------- |
| `c.Content`  | `@as`                                           | Embla's viewport, and inside it the row of slides that its attributes go on |
| `c.Item`     | `@as`                                           | A slide, as wide as the carousel unless a `basis-*` class says otherwise    |
| `c.Previous` | `@variant`, `@size`, `@icon`, `@label`, `@name` | An outline icon Button before the slides, disabled at the first             |
| `c.Next`     | `@variant`, `@size`, `@icon`, `@label`, `@name` | An outline icon Button after the slides, disabled at the last               |

`c.Previous` and `c.Next` default to `@variant="outline"` and `@size="icon-sm"`, as upstream's;
`@icon` replaces the chevron (any `lucide` icon), and `@label` their hidden names, `Previous
slide` and `Next slide`. A slide's `@as` must be a tag that can be a group (`section`, `div`),
so not `li`.

| State                                | What it is                                                    |
| ------------------------------------ | ------------------------------------------------------------- |
| `c.api`                              | Embla's API, once the carousel exists; `undefined` until then |
| `c.orientation`                      | `"horizontal"` or `"vertical"`                                |
| `c.canScrollPrev`, `c.canScrollNext` | Whether there is a slide before, and after                    |
| `c.scrollPrev`, `c.scrollNext`       | Scroll to the previous or the next slide                      |
| `c.scrollTo`                         | Scrolls to a slide by index: `(fn c.scrollTo 2)`              |

### The part modifiers

`{{c.item}}`, `{{c.previous}}` and `{{c.next}}` make an element or component of your own a
slide or a button, with the same classes and attributes as the parts (the buttons take
`variant`, `size` and `name`), and the buttons a click that steps. `c.Content` is two elements,
so it has no modifier; for markup of your own throughout, use `{{embla}}`.

```gts
<Carousel as |c|>
  <c.Content>
    {{#each this.photos as |photo|}}
      <section {{c.item}}><img src={{photo.src}} alt={{photo.alt}} /></section>
    {{/each}}
  </c.Content>
  <MyButton {{c.previous variant="ghost"}}>Back</MyButton>
</Carousel>
```

### The `embla` modifier

The headless part of `Carousel`: it makes an element an Embla viewport, as
`embla-carousel-react`'s `useEmblaCarousel` does (its first child is the track, and that child's
children the slides), and takes `options`, `plugins` and `onInit`. It reinitializes when they
change, takes the direction from the nearest `dir`, and goes with its element.

```gts
import { embla } from '@ember-joinery/carousel'

<template>
  <div class="overflow-hidden" {{embla options=(hash loop=true) onInit=this.setApi}}>
    <div class="flex">
      {{#each this.slides as |slide|}}
        <div class="min-w-0 shrink-0 basis-full">{{slide}}</div>
      {{/each}}
    </div>
  </div>
</template>
```

### Data attributes

| Element                    | Attribute              | Value                                                                |
| -------------------------- | ---------------------- | -------------------------------------------------------------------- |
| `Carousel`                 | `class`                | `jn-carousel`                                                        |
|                            | `role`                 | `region`                                                             |
|                            | `aria-roledescription` | `carousel`                                                           |
|                            | `data-slot`            | `carousel`                                                           |
|                            | `data-orientation`     | its orientation                                                      |
|                            | `data-test-jn`         | `carousel`                                                           |
|                            | `data-test-jn-name`    | its `@name`                                                          |
| `c.Content`                | `class`                | `jn-carousel-content`, and `jn-carousel-container` on the row inside |
|                            | `data-slot`            | `carousel-content` (the row has none, as upstream's)                 |
|                            | `data-test-jn-part`    | `content`, and `container` on the row                                |
| `c.Item`                   | `class`                | `jn-carousel-item`                                                   |
|                            | `role`                 | `group`                                                              |
|                            | `aria-roledescription` | `slide`                                                              |
|                            | `aria-label`           | its place, `2 of 5` (`@slideLabel`), unless it has a name of its own |
|                            | `data-slot`            | `carousel-item`                                                      |
| `c.Previous`, `c.Next`     | `class`                | a Button's, and `jn-carousel-previous` or `jn-carousel-next`         |
|                            | `data-slot`            | `carousel-previous` or `carousel-next`                               |
|                            | `aria-controls`        | the content's `id`                                                   |
| the row, items and buttons | `data-orientation`     | the carousel's orientation, which their rules key on                 |
| each part                  | `data-test-jn-part`    | `content`, `container`, `item`, `previous` or `next`                 |

## Keyboard interactions

| Key                       | What it does                                                                         |
| ------------------------- | ------------------------------------------------------------------------------------ |
| `Tab`                     | Moves focus to the buttons, and to what the slides hold                              |
| `Enter`, `Space`          | On a button, moves to the previous or next slide                                     |
| `ArrowLeft`, `ArrowRight` | Anywhere inside the carousel: the previous and the next slide; flipped right to left |
| `ArrowUp`, `ArrowDown`    | In a vertical carousel: the previous and the next slide                              |

The arrow keys work from anything focused inside the carousel, as upstream's do, except in a
text field, which keeps them to move its caret. Upstream's take only the left and right arrows,
the same way in both directions; Joinery flips them right to left, and a vertical carousel takes
the up and down arrows too. Focus that tabs into a slide out of view brings that slide into view
(Embla's `watchFocus`).

## Accessibility

It follows the [APG carousel pattern](https://www.w3.org/WAI/ARIA/apg/patterns/carousel/):

- The carousel is a `region` described as a `carousel`. Name it with `aria-label` (or
  `aria-labelledby`): a page with more than one needs each named, and the guide's examples are.
- Each slide is a `group` described as a `slide`, and named by its place (`2 of 5`), which
  upstream's aren't. Give `@slideLabel` for another language, or a slide its own `aria-label`.
- The previous and next buttons are named (visually hidden `Previous slide`, `Next slide`),
  control the content (`aria-controls`), and are disabled at either end. They are
  `type="button"`, so in a form they don't submit, which upstream's would.
- An autoplaying carousel (the Plugins example) must stop when the pointer is over it or focus
  is inside it, as Autoplay's `stopOnInteraction` and `stopOnFocusIn` and the example's
  `mouseenter` do.

## Testing

`CarouselHarness` from `@ember-joinery/carousel/test-support` drives a `Carousel`. It reads
which slides are in view from where they are drawn, as a user sees them, and moves the carousel
the ways a user does. Every action waits for the carousel to come to rest:

```ts
import { CarouselHarness } from '@ember-joinery/carousel/test-support'

const carousel = new CarouselHarness('gallery') // <Carousel @name="gallery">
assert.deepEqual(carousel.slidesInView, [0])
await carousel.scrollNext()
await carousel.press('ArrowRight')
await carousel.swipe('previous')
assert.deepEqual(carousel.slidesInView, [1])
```

| Member                           | What it is                                                           |
| -------------------------------- | -------------------------------------------------------------------- |
| `orientation`, `direction`       | `horizontal` or `vertical`; `ltr` or `rtl`                           |
| `label`, `roleDescription`       | Its accessible name, and `carousel`                                  |
| `content`, `container`           | Embla's viewport, and the row of slides inside it                    |
| `slides`, `slideCount`           | The slides, and how many                                             |
| `slideLabels`, `slideTexts`      | Each slide's accessible name, and its text                           |
| `slidesInView`, `currentSlide`   | The slides at least half in view, by index, and the first of them    |
| `previous`, `next`               | The buttons (`null` without them)                                    |
| `canScrollPrev`, `canScrollNext` | Whether each button can be used                                      |
| `scrollPrev()`, `scrollNext()`   | Click a button                                                       |
| `press(key)`                     | Presses a key inside it, focusing a button first if focus is outside |
| `swipe(to)`, `drag(distance)`    | Swipe to the `next` or `previous` slide; or drag by so many pixels   |
| `waitForSlide(index)`            | Waits for a slide to come into view, as when autoplay moves it       |

`settled()`, and so every `@ember/test-helpers` action, waits while a carousel is moving, so
any test sees its slides where they stop. Each example's Test tab has a whole test.

## Upstream

shadcn/ui's [Carousel](https://ui.shadcn.com/docs/components/radix/carousel), from
`apps/v4/registry/bases/radix/ui/carousel.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
