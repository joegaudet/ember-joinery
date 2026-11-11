import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { onResize } from '@ember-joinery/primitives/on-resize'

/** Shows its own size as you drag its corner: one ResizeObserver serves the whole app. */
export default class OnResizeMeasure extends Component {
  @tracked size = ''

  measure = (entry: ResizeObserverEntry) => {
    const { width, height } = entry.contentRect
    this.size = `${Math.round(width)} × ${Math.round(height)}`
  }

  <template>
    <div
      data-test-jn="measured"
      style="resize: both; overflow: hidden; width: 14rem; height: 6rem; padding: 0.5rem; border: 2px dashed; box-sizing: border-box;"
      {{onResize this.measure}}
    >
      Drag the corner to resize me.
      <p><output data-test-jn-part="size">{{this.size}}</output></p>
    </div>
  </template>
}
