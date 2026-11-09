import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, waitForObservers } from '@ember-joinery/test-support'
import ResizeObserverDemo from 'docs-app/examples/resize-observer-demo'

class ResizableHarness extends Harness {
  static component = 'resizable'

  get size() {
    return this.element.textContent!.trim()
  }

  /** What dragging the corner does: sets the box's size. Waits for the resize to arrive. */
  async resizeTo(width: number, height: number) {
    const box = this.element
    box.style.width = `${width}px`
    box.style.height = `${height}px`
    await waitForObservers()
  }
}

module('Example | resize-observer-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('the element shows its own size, and follows each resize', async function (assert) {
    await render(<template><ResizeObserverDemo /></template>)
    const box = new ResizableHarness()
    assert.true(box.size.startsWith('( '), 'measured at the start')

    // The content box: the size less 2px borders and 0.5rem (8px) of padding on each side.
    await box.resizeTo(300, 120)
    assert.strictEqual(box.size, '( 280 x 100 )')

    await box.resizeTo(200, 90)
    assert.strictEqual(box.size, '( 180 x 70 )')
    await a11yAudit()
  })
})
