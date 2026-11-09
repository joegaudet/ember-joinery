# Hero

The hero pattern is for featuring large, eye-catching content, such as an image or video, along
with a clear, easy to read headline or call to action. It is ember-primitives' `Hero`.

<Example @name="hero-demo" @title="A hero, sized to the preview" />

## Features

- Covers the full browser height and width, including proper dimensionality on dynamically
  sized viewports, such as on mobile.

## Usage

```gts
import { Hero } from '@ember-joinery/primitives/hero'

<template>
  <Hero>
    content
  </Hero>
</template>
```

The Hero is a `<div>` with `data-jn-hero`, the attributes, and three rules: `width: 100dvw`,
`height: 100dvh` (the dynamic viewport units, which follow a phone's toolbars as they come and
go) and `position: relative`, so elements within can be sticky or absolutely positioned along
the outside, if needed (such as for headers and footers). The rules are in `@layer joinery` at
no specificity, so a class of yours resizes it, as the example's do to fit the preview. A
Tailwind utility is in a layer of its own, so it wins once `joinery` comes before that layer,
as the guide's [Tailwind setup](/getting-started/installation.md#tailwind-apps) has it: see
[layout rules](/primitives/index.md#layout-rules-and-your-css-layers).

## API

| Argument | Type     | What it does              |
| -------- | -------- | ------------------------- |
| `@name`  | `string` | Its name, for its harness |

It has no state.

### From ember-primitives

The same component. ember-primitives' rules come from a CSS file its module imports, on the
class `ember-primitives__hero__wrapper`; Joinery's come with the component, on `data-jn-hero`,
and need nothing imported. Its attributes go on the same element.

## Accessibility

This component provides no accessibility patterns: using `<main>`, `<header>` or `<footer>`
inside or around it, or none, is up to what the Hero is for.

## Testing

`HeroHarness` reads its size. A Hero wraps your content, so it is a wrapper for the harnesses
(`data-test-jn-wrapper`): a part inside it still belongs to the component around it.

```ts
import { HeroHarness } from '@ember-joinery/test-support'

const hero = new HeroHarness()
hero.size // { width, height }
hero.fillsViewport // as wide and as tall as the window
```
