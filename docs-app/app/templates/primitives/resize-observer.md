# Resize Observer

`resizeObserver(this)` is the app's one `ResizeObserver`, for watching an element's size from
JavaScript. One observer for every element is much cheaper than one each, and the browser's
harmless "ResizeObserver loop" message doesn't fail tests or reach error trackers. In a
template, [`{{onResize}}`](/primitives/on-resize.md) uses it for you. It is ember-primitives'
`resizeObserver`.

<Example @name="resize-observer-demo" @title="An element that shows its size" />

## Usage

```ts
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { modifier } from 'ember-modifier'
import { resizeObserver } from '@ember-joinery/primitives/resize-observer'

class Chart extends Component {
  @tracked width = 0
  redraw = (entry: ResizeObserverEntry) => (this.width = entry.contentRect.width)

  watch = modifier(element => {
    const observer = resizeObserver(this)
    observer.observe(element, this.redraw)
    return () => observer.unobserve(element, this.redraw)
  })
}
```

The callback hears the element's size once at the start, once it has one, and on each change.
Pass `unobserve` the same function, as with `removeEventListener`. A second callback for an
element already observed hears its current size too, and the first hears nothing new.

## API

| Export                    | What it does                                                          |
| ------------------------- | --------------------------------------------------------------------- |
| `resizeObserver(context)` | The app's shared observer (one per owner, so one per test)            |
| `.observe(el, callback)`  | Calls `callback(entry)` at the start and each time `el` resizes       |
| `.unobserve(el, cb)`      | Stops calling `cb` for `el`; the last one stops observing `el`        |
| `ignoreROError()`         | Silences the "ResizeObserver loop" message (`resizeObserver` does it) |
| `ResizeObservers` (class) | The type `resizeObserver()` returns                                   |

`context` is anything with an owner (a component, a route), or the owner itself.

### From ember-primitives

The same. Joinery's `ignoreROError` also catches the message as an `error` event on `window`,
not only through `window.onerror`, and a new callback for an element already observed hears
its current size, where ember-primitives' waits for the next change.

## Testing

`settled()` waits for an element's first report. After a change of size, `waitForObservers()`
from `@ember-joinery/test-support` waits for the next.
