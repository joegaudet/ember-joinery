# On Resize

`{{onResize}}` calls a function each time an element changes size, with its
`ResizeObserverEntry`. Every `{{onResize}}` in the app shares one `ResizeObserver`, which is
much cheaper than one each, and the browser's harmless "ResizeObserver loop" message doesn't
fail tests or reach error trackers. They are ember-primitives' `onResize` and `resizeObserver`.

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

The function runs once at the start, once the element has a size, and on each change. In
JavaScript, `resizeObserver(this)` is the shared observer:
`resizeObserver(this).observe(element, callback)` and `.unobserve(element, callback)`.

## API

| Export                    | What it does                                                           |
| ------------------------- | ---------------------------------------------------------------------- |
| `{{onResize callback}}`   | Calls `callback(entry)` at the start and on each resize                |
| `resizeObserver(context)` | The app's shared observer: `observe(element, callback)`, `unobserve`   |
| `ignoreROError()`         | Silences the "ResizeObserver loop" message (`resizeObserver` calls it) |

## Testing

`settled()` waits for the first report. After a change of size, `waitForObservers()` from
`@ember-joinery/test-support` waits for the next:

```ts
import { waitForObservers } from '@ember-joinery/test-support'

panel.style.width = '300px'
await waitForObservers()
assert.dom('output').hasText('300')
```
