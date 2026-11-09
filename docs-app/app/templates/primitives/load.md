# Load

`load()` makes a component that loads another, for splitting a bundle by hand: it shows its
`<:loading>` block while an `import()` (or any promise) is pending, `<:error>` if it fails, and
the loaded component once it is there. It is ember-primitives' `load`.

<Example @name="load-on-demand" @title="A component loaded when it renders" />

## Usage

```gts
import { load } from '@ember-joinery/primitives/load'

const Chart = load(() => import('./revenue-chart.gts'))

<template>
  <Chart>
    <:loading>Loading the chart…</:loading>
    <:error as |error|>The chart didn't load: {{error.reason}}</:error>
    <:success as |RevenueChart|><RevenueChart @year={{2026}} /></:success>
  </Chart>
</template>
```

It takes a component, a promise of one, or a function returning either; an imported module
stands for its default export. A function is called the first time the component renders, and
only then; the result is kept, so later renders show it at once. Without a `<:success>` block,
the loaded component renders on its own, with no arguments. Type the loaded component's
signature with `load<Signature>(…)`.

## API

| Block        | Yields                 | When                                            |
| ------------ | ---------------------- | ----------------------------------------------- |
| `<:loading>` |                        | While the promise is pending                    |
| `<:error>`   | `{ reason, original }` | When the function threw or the promise rejected |
| `<:success>` | the loaded component   | Once it has loaded                              |

`reason` says which step failed (`"Passed function threw an exception"` or `"Promise rejected
while waiting to resolve"`) and `original` is what was thrown.

### From ember-primitives

The same API. Joinery also unwraps an `import()`'s module, treats a class component as the
value rather than a function to call, and renders the component itself when there is no
`<:success>` block.

## Testing

`render()` and `settled()` wait for the promise, so the loaded component is there when they
resolve.
