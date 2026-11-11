# Head

`InHead` renders its block into the document's `<head>`, after what is there, and takes it out
again when it stops rendering: a stylesheet only one page needs, a page's own `<meta>` tags, or
a script loaded on demand. It is ember-primitives' `InHead`.

<Example @name="head-stylesheet" @title="A stylesheet while it is wanted" />

## Usage

```gts
import { InHead } from '@ember-joinery/primitives/head'

<template>
  <InHead>
    <meta name="description" content={{@model.summary}} />
    <link rel="canonical" href={{@model.url}} />
  </InHead>
</template>
```

Everything in the block is reactive, like any other template: change `@model.summary` and the
`<meta>` changes with it.

## API

`InHead` takes no arguments; its block is what goes in `<head>`.

## Testing

What `InHead` renders is in `document.head`, not in the test's root element, so look for it
there: `document.head.querySelector('meta[name="description"]')`.
