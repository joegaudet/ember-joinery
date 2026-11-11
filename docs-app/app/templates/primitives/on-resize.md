# On Resize

`{{onResize}}` calls a function each time an element changes size, with its
`ResizeObserverEntry`. Every `{{onResize}}` in the app shares one `ResizeObserver`, which is
much cheaper than one each, and the browser's harmless "ResizeObserver loop" message doesn't
fail tests or reach error trackers. It is ember-primitives' `onResize`.

<Example @name="on-resize-measure" @title="A box that shows its size" />

## Usage

```gts
import { onResize } from '@ember-joinery/primitives/on-resize'

class Panel extends Component {
  @tracked width = 0
  measure = (entry: ResizeObserverEntry) => (this.width = entry.contentRect.width)

  <template>
    <div {{onResize this.measure}}>…</div>
  </template>
}
```

The function runs once at the start, once the element has a size, and on each change. Pass a
new function and the old one stops. In JavaScript, use the same shared observer with
[`resizeObserver(this)`](/primitives/resize-observer.md).

## API

| Export                  | What it does                                            |
| ----------------------- | ------------------------------------------------------- |
| `{{onResize callback}}` | Calls `callback(entry)` at the start and on each resize |

### From ember-primitives

The same modifier. ember-primitives' `on-resize` also re-exports `ignoreROError`; import it from
[`resize-observer`](/primitives/resize-observer.md), where it lives in both.

## Testing

`settled()` waits for the first report. After a change of size, `waitForObservers()` from
`@ember-joinery/test-support` waits for the next:

```ts
import { waitForObservers } from '@ember-joinery/test-support'

panel.style.width = '300px'
await waitForObservers()
assert.dom('output').hasText('300')
```
