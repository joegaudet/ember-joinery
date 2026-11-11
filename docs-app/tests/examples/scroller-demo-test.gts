import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, ScrollerHarness, child } from '@ember-joinery/test-support'
import ScrollerDemo from 'docs-app/examples/scroller-demo'

type Edge = 'left' | 'right' | 'top' | 'bottom'

/** The demo: a Scroller, and four buttons beside it that scroll it to each edge. */
class ScrollerDemoHarness extends Harness {
  static override component = 'scroller-demo'

  @child(ScrollerHarness) declare scroller: ScrollerHarness

  /** The button that scrolls to `edge`. */
  button(edge: Edge): HTMLElement {
    return this.part('scroll-to', edge)
  }

  /** Presses the button for `edge`; the click waits for the scroll to end, a smooth one too. */
  async scrollTo(edge: Edge): Promise<void> {
    await click(this.button(edge))
  }
}

module('Example | scroller-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('the four buttons scroll the box to each edge', async function (assert) {
    await render(<template><ScrollerDemo /></template>)
    const demo = new ScrollerDemoHarness()
    const { scroller } = demo
    assert.true(scroller.isAtTop && scroller.isAtLeft)
    assert.dom(demo.button('right')).hasAria('label', 'Scroll to the right')

    // The box scrolls smoothly (its CSS); each click waits for the scroll to end.
    await demo.scrollTo('right')
    assert.true(scroller.isAtRight && scroller.isAtTop, 'right')
    await demo.scrollTo('left')
    assert.true(scroller.isAtLeft, 'left')
    await demo.scrollTo('bottom')
    assert.true(scroller.isAtBottom && scroller.isAtLeft, 'down')
    await demo.scrollTo('right')
    assert.true(scroller.isAtBottom && scroller.isAtRight, 'and right, staying at the bottom')
    await demo.scrollTo('top')
    assert.true(scroller.isAtTop && scroller.isAtRight, 'up')
    await a11yAudit()
  })
})
