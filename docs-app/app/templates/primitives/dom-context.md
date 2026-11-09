# DOM Context

Data shared with everything rendered inside a provider, as React's context is: `<Provide>`
makes the data and `<Consume>` reads the nearest provider's, found by walking up the DOM.
Reading it is synchronous and reactive. They are ember-primitives' `Provide` and `Consume`.

<Example @name="dom-context-counter" @title="One counter, two consumers" />

## Usage

```gts
import { tracked } from '@glimmer/tracking'
import { Consume, Provide } from '@ember-joinery/primitives/dom-context'

class Theme {
  @tracked accent = 'violet'
}

<template>
  <Provide @data={{Theme}}>
    <Consume @key={{Theme}} as |theme|>
      <p>The accent is {{theme.data.accent}}.</p>
    </Consume>
  </Provide>
</template>
```

A class or function as `@data` is made into one instance for that provider, with its owner and
lifetime (as [`createStore`](/primitives/store.md) does); anything else is given as is. The
consumer's `@key` is the provider's `@data`, or its `@key`, and a class key types the data.
Providers with the same key are independent: a consumer reads the nearest one above it.

## API

`Provide`:

| Argument   | Type                       | Default | What it does                                          |
| ---------- | -------------------------- | ------- | ----------------------------------------------------- |
| `@data`    | a value, class or function |         | What the subtree gets                                 |
| `@key`     | `string \| object`         | `@data` | What consumers ask for                                |
| `@element` | tag name \| `false`        | `div`   | The provider's element (`display: contents`), or none |

With `@element={{false}}` the provider marks its place with an empty text node, so it adds no
element at all, but siblings that come after it can find it too, not only its descendants.

`Consume` takes `@key` and yields `{ data }`. Reading `data` with no provider above throws.
