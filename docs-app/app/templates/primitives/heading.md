# Heading

The `<Heading>` component correlates to the `<h1>` through `<h6>` [section
heading](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/Heading_Elements)
elements, where the **level** is determined _automatically_ based on how the DOM has rendered.
It is ember-primitives' `Heading`.

This enables distributed teams to correctly produce appropriate section heading levels without
knowledge of where their work will be rendered in the overall document, and is extra helpful
for design systems teams, where it is _not possible_ to know the appropriate heading level ahead
of time.

## Usage

In your app, you can use any of `<section>`, `<article>`, `<aside>` and `<nav>` elements to
denote when the section heading element should change its level. On this page the demo's first
heading is an `h3`, because the page already has an `h1`, and this section (Usage) uses an
`h2`. On its own, as in its test, it starts at `h1`.

<Example @name="heading-demo" @title="Headings in sections" />

```gts
import { Heading } from '@ember-joinery/primitives/heading'

<template>
  <Heading>Settings</Heading>
  {{! <h1> at the top of the page }}
  <section>
    <Heading>Profile</Heading>
    {{! <h2> }}
  </section>
</template>
```

A heading is one level below the nearest heading before it in the section around it, and an
`h1` when there is none. `<section>`, `<article>`, `<aside>` and `<nav>` start a section; a
`<header>`, `<footer>` or `<main>` is looked inside, as it usually holds its section's heading.
A section with no heading of its own is passed through, so it doesn't start again at `h1`. The
level is found once, as the heading first renders, from the document as it is then, and stops
at `h6`.

## Heading level

`getSectionHeadingLevel(node)` is what `<Heading>` uses, for headings of your own: it says
which level, 1 to 6, belongs at a node in the document. A text node, rendered just before the
heading, is where the search starts, all in one render. This is upstream's own heading, written
on it:

<Example @name="heading-custom" @title="A heading of your own" />

`{ startAt }` is the level to use when nothing above the node sets one (default 1); it doesn't
lower a level the document sets. The first answer for a node is kept, so ask once the node is
where it will stay.

## API

| Argument | Type     | What it does              |
| -------- | -------- | ------------------------- |
| `@name`  | `string` | Its name, for its harness |

Attributes go on the heading. The module also exports `getSectionHeadingLevel(node, options?)`
and the `HeadingLevel` type (`1 | 2 | 3 | 4 | 5 | 6`).

### From ember-primitives

The same component, and the same algorithm as its `which-heading-do-i-need` package, in
`@ember-joinery/primitives/heading` with no dependency. A heading below an `h6` is an `h6`
(ember-primitives' would be an `h7`, which isn't an element), and the search also works in an
iframe and from a node at the top of a shadow root.

## Accessibility

Screen reader users move through a page by its headings, so their levels matter: a section's
heading one level below the page's, and so on. `<Heading>` keeps them right wherever a
component is used.

## Testing

`HeadingHarness` reads the level it chose. A Heading wraps its text, so it is a wrapper for the
harnesses (`data-test-jn-wrapper`): a part inside it still belongs to the component around it,
and a Heading can be a part itself (`<Heading data-test-jn-part="title">`).

```ts
import { HeadingHarness } from '@ember-joinery/test-support'

const title = new HeadingHarness('title') // <Heading @name="title">
title.level // 2
title.text
```
