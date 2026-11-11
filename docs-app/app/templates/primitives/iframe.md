# Iframe

`inIframe()` says whether the page is running inside a frame (an `<iframe>`, or an embed on
another site), and `notInIframe()` the opposite. Both work in JavaScript and in templates. They
are ember-primitives' `inIframe` and `notInIframe`.

<Example @name="iframe-embedded" @title="A notice for embedded pages" />

## Usage

```gts
import { inIframe } from '@ember-joinery/primitives/iframe'

<template>
  {{#if (inIframe)}}
    <a href={{this.fullPageURL}} target="_top">Open the full page</a>
  {{/if}}
</template>
```

## API

| Export          | What it returns                              |
| --------------- | -------------------------------------------- |
| `inIframe()`    | `true` when the page is inside a frame       |
| `notInIframe()` | `true` when the page is the top-level window |

## Testing

Tests run in the top-level window, so `inIframe()` is `false` there.
