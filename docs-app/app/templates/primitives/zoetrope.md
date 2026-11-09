# Zoetrope

A slider style element built using browser native scrolling to create netflix style carousels.
It is ember-primitives' `Zoetrope`.

<Example @name="zoetrope-demo" @title="Sixty cards" />

## Usage

```gts
import { Zoetrope } from '@ember-joinery/primitives/zoetrope'

<template>
  <Zoetrope @gap={{8}} @offset={{40}} aria-label="New releases">
    <:header>
      <h2>New releases</h2>
    </:header>

    <:content>
      {{#each this.films as |film|}}
        <a href={{film.url}} class="card">{{film.title}}</a>
      {{/each}}
    </:content>
  </Zoetrope>
</template>
```

## Features

- Automatic page size detection.
- Provide your own custom control buttons.
- CSS variables to control gap and offset.
- Keyboard navigation.

A button scrolls by as many items as fit. The buttons show only when the items overflow, and
each is disabled at its end. The track snaps to each item's start and hides its scrollbar. Its
layout rules are in `@layer joinery` at no specificity, so any CSS of yours wins; select its
parts by their attributes: `data-jn-zoetrope`, `data-jn-zoetrope-header`,
`data-jn-zoetrope-controls` and `data-jn-zoetrope-scroller`.

## Custom Controls

You can pass your own control buttons to the zoetrope component. Give an element
`data-jn-zoetrope-controls` to place them in the default position, or style them as you
wish. The `<:controls>` block is given `scrollLeft`, `scrollRight`, `canScroll`,
`cannotScrollLeft` and `cannotScrollRight`.

<Example @name="zoetrope-custom-controls" @title="Default placement" />

<Example @name="zoetrope-custom-placement" @title="Custom placement" />

## Scroll Behavior

The component takes a `@scrollBehavior` argument that can be used to control the scroll
behavior. The default value is `smooth`. When the system asks for reduced motion, the scroll is
always `instant`.

<Example @name="zoetrope-instant-scroll" @title="Instant scroll" />

## API

| Argument            | Type                              | Default  | What it does                                                             |
| ------------------- | --------------------------------- | -------- | ------------------------------------------------------------------------ |
| `@gap`              | `number`                          | `8`      | The space between items, in pixels (`--zoetrope-gap`)                    |
| `@offset`           | `number`                          | `0`      | The space before the first item and after the last (`--zoetrope-offset`) |
| `@scrollBehavior`   | `'smooth' \| 'instant' \| 'auto'` | `smooth` | How the buttons and Tab scroll; always instant for reduced motion        |
| `@scrollLeftLabel`  | `string`                          | `Left`   | The default left button's text                                           |
| `@scrollRightLabel` | `string`                          | `Right`  | The default right button's text                                          |
| `@name`             | `string`                          |          | Its name, for its harness                                                |

| Block         | What it holds                                                        |
| ------------- | -------------------------------------------------------------------- |
| `<:header>`   | A heading, on the line above the items, beside the controls          |
| `<:content>`  | The items, side by side in the track                                 |
| `<:controls>` | Your own buttons, in place of the default ones, given what they need |

Attributes go on the `<section>`.

### From ember-primitives

The same component. In right-to-left text the track starts on the right, and the buttons
still scroll the way they name (ember-primitives' measure from the left only). The default
buttons' text is an argument. Tab from an item to the next brings it to the start, as in
ember-primitives, and only from an item itself: from a button inside an item, Tab goes to the
next button as usual. And it scrolls smoothly in tests too, where ember-primitives scrolls
instantly: it holds a test waiter until each scroll ends, so tests see where it stopped either
way.

## Keyboard interactions

| Key         | What it does                                                      |
| ----------- | ----------------------------------------------------------------- |
| `Tab`       | From an item, moves to the next one and scrolls it to the start   |
| `Shift+Tab` | From an item, moves to the one before and scrolls it to the start |

When the next item can't take focus, the key is left to the browser, so the Zoetrope never
traps the keyboard.

## Accessibility

The `<section>` needs a name before screen readers treat it as a region. Pass `aria-label`.

The default buttons say "Left" and "Right". Pass `@scrollLeftLabel` and `@scrollRightLabel`,
or use the `<:controls>` block, to give them names that say what they scroll.

## Testing

`ZoetropeHarness` is ember-primitives' `ZoetropeHelper` as a harness: the items, which are in
view, and the buttons. `scrollLeft()` and `scrollRight()` click the `scroll-left` and
`scroll-right` parts: the default buttons, or yours when they carry
`data-test-jn-part="scroll-left"` and `"scroll-right"`, as the custom controls above do.

```ts
import { ZoetropeHarness } from '@ember-joinery/test-support'

const releases = new ZoetropeHarness('releases') // <Zoetrope @name="releases">
releases.items // every item
releases.visibleItems // the ones in view; visibleItemCount counts them
releases.canScrollLeft // also canScrollRight
releases.scrolled // how far, in pixels
await releases.scrollRight() // also scrollLeft(); waits for the scroll to end
await releases.focusItem(0) // releases.focusedIndex
releases.header // also controls, scroller, leftButton, rightButton
```
