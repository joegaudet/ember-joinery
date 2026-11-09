# IncrementalEach

A drop-in replacement for `{{#each}}` that renders a collection a batch at a time during the
browser's idle periods. It is ember-primitives' `IncrementalEach`.

Every item ends up in the DOM, so browser find (Ctrl+F / Cmd+F), anchor links, screen readers,
print, and SEO all work against the full list. Yielding the main thread between batches keeps
the page responsive (clicks, scrolling, hover effects keep working) while the rest of the list
is filling in.

Use this for non-scrollable containers, or anywhere a virtual/windowed list does not apply
(variable item heights, lists that grow the page, surfaces that need every row indexable). For
a fixed-size scrollable viewport with a known item size, a virtual list will use less memory and
produce less DOM.

## Usage

The demo renders 20,000 rows in batches of 400. Use Ctrl+F / Cmd+F to search for any row number
to confirm every row is real DOM. Toggle the button to unmount and re-mount the list: each
"Show" brings back the first batch in the same paint (in `sync` mode), then the rest streams in.

<Example @name="incremental-each-demo" @title="20,000 rows" />

```gts
import { IncrementalEach } from '@ember-joinery/primitives/incremental-each'

<template>
  <ul>
    <IncrementalEach @items={{this.items}} @batchSize={{50}} @initial="sync" as |item index|>
      <li>{{index}}: {{item}}</li>
    </IncrementalEach>
  </ul>
</template>
```

It renders no element of its own. Don't nest one inside another: each level waits for its own
batches, so inner rows appear to flicker in with missing content. If you have nested loops,
make only the outermost one an `<IncrementalEach>`, and leave the deeper ones as `{{#each}}`.

## API

| Argument     | Type               | Default | What it does                                                                     |
| ------------ | ------------------ | ------- | -------------------------------------------------------------------------------- |
| `@items`     | `readonly T[]`     |         | The items. A new array (a new identity) starts again from the first batch        |
| `@batchSize` | `number`           | `50`    | How many items each batch adds; more than 0                                      |
| `@initial`   | `'sync' \| 'lazy'` | `sync`  | `sync`: the first batch is in the first paint. `lazy`: it waits a batch, too     |
| `@onDone`    | `() => void`       |         | Called once every item has rendered, again for each new `@items`, never for none |

It yields each item and its index in `@items`, as `{{#each}}` does. A change to one item (a
tracked property on it) re-renders that item only.

### From ember-primitives

The same component. It needs no `ember-resources`, and `@onDone` is called again when `@items`
goes back to an array it showed before.

## Testing

`IncrementalEach` holds a test waiter while batches are pending, so `await render(...)` and
`await settled()` both wait for every batch, and tests can check the whole list as with
`{{#each}}`. It has no harness of its own, as it renders no element: its rows are the parts of
the component around it.
