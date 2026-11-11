# @ember-joinery/code-block

shadcn/ui's [Code Block](https://ui.shadcn.com/docs/components/radix/code-block) for Ember, an
opt-in add-on to [Joinery](https://joegaudet.com/ember-joinery/): code, terminal output, logs
and diffs, with a header, line numbers, highlighted lines, wrapping and a copy button. Syntax
highlighting is optional: `highlightedCode` runs [Shiki](https://shiki.style) with its
JavaScript engine (no WASM), and Shiki and each language load the first time they are used.

```bash
npm install @ember-joinery/code-block @ember-joinery/ember
```

It ships no CSS of its own: `@ember-joinery/ember`'s `joinery.css` (or any of its styles)
styles its parts, as it does every Joinery component.

```gts
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

<template>
  <CodeBlock as |b|>
    <b.Header>
      <b.Title>app/api/chat/route.ts</b.Title>
      <b.Actions><b.CopyButton @value={{code}} /></b.Actions>
    </b.Header>
    <b.Content @lineNumbers={{true}}>
      {{#each (highlightedCode code "ts") as |line|}}<b.Line @code={{line}} />{{/each}}
    </b.Content>
  </CodeBlock>
</template>
```

Its harness, `CodeBlockHarness`, is in `@ember-joinery/code-block/test-support`, with
`setupClipboard()` for testing the copy button.

Full documentation: the Code Block page of the guide at
**https://joegaudet.com/ember-joinery/guide/**. Design and API ported from
[shadcn/ui](https://ui.shadcn.com/) (MIT).
