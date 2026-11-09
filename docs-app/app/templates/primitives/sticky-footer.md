# Sticky Footer

A common UI pattern is to have a footer area at the bottom of the page that always sticks to the
bottom of the window, regardless of how little content there is on the page, yet allows
scrolling and being pushed out of frame when there is a lot of content, as the footer is not
"main" content on the page, but typically more "reference" material, or serving a navigation
purpose.

This component implements a CSS/markup-only pattern for the above-described layout-pattern. It
is ember-primitives' `StickyFooter`.

<Example @name="sticky-footer-demo" @title="Add content to push the footer down" />

## Example: perma sticky / revealing footer

In this example, there is an extra footer at the bottom, and we want the sticky footer to always
show above that, but then reveal more information when we scroll to the bottom.

<Example @name="sticky-footer-revealing" @title="A footer that reveals more" />

## Features

- Footer sticks to the bottom of the window when there is less than a screen's worth of content
- Footer sits below the content when there is enough content to overflow the containing element
  / body

## Usage

```gts
import { StickyFooter } from '@ember-joinery/primitives/sticky-footer'

<template>
  <StickyFooter>
    <:content>
      content here
    </:content>
    <:footer>
      footer content here
    </:footer>
  </StickyFooter>
</template>
```

The wrapper, which has the attributes, scrolls and fills its parent (`height: 100%`), so the
parent needs a height or a max-height. Inside it, a grid at least as tall gives the content the
space the footer doesn't take. Each element has an attribute to style it by:

```css
/* the wrapper, which scrolls: the element with the attributes */
[data-jn-sticky-footer]
  /* the grid that holds both <:content> and <:footer> */
  [data-jn-sticky-footer-container]
  /* the <:content> block's element */
  [data-jn-sticky-footer-content]
  /* the <:footer> block's element */
  [data-jn-sticky-footer-footer]
```

The rules are in `@layer joinery` at no specificity, so your CSS wins (in CSS layers of your
own, once `joinery` comes before them: see
[layout rules](/primitives/index.md#layout-rules-and-your-css-layers)).

## API

| Argument | Type     | What it does              |
| -------- | -------- | ------------------------- |
| `@name`  | `string` | Its name, for its harness |

| Block        | What it holds                                                 |
| ------------ | ------------------------------------------------------------- |
| `<:content>` | The content, which scrolls; a page's `<main>` belongs in here |
| `<:footer>`  | The footer; a `<footer>` belongs in here                      |

It has no state.

### From ember-primitives

The same component. ember-primitives' elements have BEM classes
(`ember-primitives__sticky-footer__wrapper`…) from a CSS file its module imports; Joinery's
have `data-jn-sticky-footer-*` attributes, and their rules come with the component. Its attributes go on the wrapper,
as in ember-primitives.

## Accessibility

This component provides no accessibility patterns: using `<main>` and `<footer>`, or not, is
up to what the StickyFooter is for.

## Testing

`StickyFooterHarness` finds the content and the footer, and says where the footer is. A
StickyFooter wraps your content, so it is a wrapper for the harnesses
(`data-test-jn-wrapper`): a part inside it still belongs to the component around it.

```ts
import { StickyFooterHarness } from '@ember-joinery/test-support'

const layout = new StickyFooterHarness()
layout.content // the <:content> block's element; footer, the <:footer> block's
layout.overflows // whether it scrolls
layout.isFooterAtBottom // at the bottom of the view
layout.isFooterVisible
await layout.scrollToEnd() // also scrollToTop()
```
