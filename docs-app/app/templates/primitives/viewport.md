# Viewport

Knowing when elements scroll into view, without an `IntersectionObserver` for each: `viewport()`
is the app's shared observers, and `InViewport` renders its block only once it comes near the
view, for content below the fold that is expensive to render. They are ember-primitives'
`viewport` and `InViewport`.

<Example @name="viewport-deferred" @title="Comments rendered as they scroll in" />

## Usage

```gts
import { InViewport } from '@ember-joinery/primitives/viewport'

<template>
  <InViewport @rootMargin="200px" class="chart-slot">
    <RevenueChart />
  </InViewport>
</template>
```

Until it comes near the view, `InViewport` renders an empty element (a `div`, or `@tagName`)
with its attributes, to be watched; give it the size the content will have, so the page doesn't
jump. Once the block renders it stays. With `@mode="replace"`, the block takes the element's
place rather than going inside it.

### Contain mode (the default)

The block renders inside `InViewport`'s element, which stays in the page around it:

<Example @name="viewport-contain" @title="Content in contain mode" />

### Replace mode

With `@mode="replace"`, the block takes the element's place, and the element goes:

<Example @name="viewport-replace" @title="Content in replace mode" />

### A custom tag name

`@tagName` picks the element (a `div` by default):

<Example @name="viewport-tag-name" @title="A section as the placeholder" />

### The shared observers

For your own observing, `viewport(this)` is one set of observers per app (per test, in tests):

<Example @name="viewport-visibility" @title="Watching an element with the shared observer" />

```ts
import { modifier } from 'ember-modifier'
import { viewport } from '@ember-joinery/primitives/viewport'

class Video extends Component {
  @tracked visible = false
  onChange = (entry: IntersectionObserverEntry) => (this.visible = entry.isIntersecting)

  watch = modifier(element => {
    const observers = viewport(this)
    observers.observe(element, this.onChange, { threshold: 0.5 })
    return () => observers.unobserve(element, this.onChange)
  })
}
```

Every element observed with the same options shares one `IntersectionObserver`. The callback
hears where the element is at the start, then each time it crosses into or out of view (or past
a threshold). Pass `unobserve` the same function, as with `removeEventListener`.

## API

`InViewport`:

| Argument      | Type                     | Default   | What it does                                              |
| ------------- | ------------------------ | --------- | --------------------------------------------------------- |
| `@mode`       | `'contain' \| 'replace'` | `contain` | The block goes inside the element, or in its place        |
| `@tagName`    | `string`                 | `div`     | The element's tag                                         |
| `@rootMargin` | `string`                 | `0px`     | How near counts, as `IntersectionObserver`'s `rootMargin` |

`viewport(context).observe(element, callback, options?)` and `.unobserve(element, callback)`;
the options are `rootMargin` and `threshold`, as `IntersectionObserver` takes them.

### From ember-primitives

The same, plus `InViewport`'s `@rootMargin`. ember-primitives' `viewport` shares one observer
and ignores the options its docs describe; Joinery's honours them, with one observer for each
set of options.

## Testing

`settled()` waits for each observed element's first report. A scroll's reports come in the next
frame, so `@ember-joinery/test-support` has `scrollIntoView(target)`, which scrolls to an element
(or selector) as a user would and waits for them, and `waitForObservers()` for after any other
change:

```ts
import { scrollIntoView } from '@ember-joinery/test-support'

await render(<template><Article /></template>)
assert.dom('[data-test-comment]').doesNotExist()
await scrollIntoView('[data-test-comments]')
assert.dom('[data-test-comment]').exists({ count: 3 })
```

`InViewport` has no harness of its own: it is a transparent wrapper, and marking it as a
component would take the parts inside it from the harness of the component around it.
