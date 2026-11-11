import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, waitForObservers } from '@ember-joinery/test-support'
import OnResizeMeasure from 'docs-app/examples/on-resize-measure'

class MeasuredHarness extends Harness {
  static component = 'measured'

  get size() {
    return this.part('size').textContent!.trim()
  }

  /** What dragging the corner does: sets the box's size. Waits for the resize to arrive. */
  async resizeTo(width: number, height: number) {
    const box = this.element as HTMLElement
    box.style.width = `${width}px`
    box.style.height = `${height}px`
    await waitForObservers()
  }
}

module('Example | on-resize-measure', function (hooks) {
  setupRenderingTest(hooks)

  test('it shows its size, and follows each resize', async function (assert) {
    await render(<template><OnResizeMeasure /></template>)
    const box = new MeasuredHarness()
    assert.notStrictEqual(box.size, '', 'measured at the start')

    // The content box: the size less 2px borders and 0.5rem (8px) of padding on each side.
    await box.resizeTo(300, 120)
    assert.strictEqual(box.size, '280 × 100')

    await box.resizeTo(200, 100)
    assert.strictEqual(box.size, '180 × 80')
    await a11yAudit()
  })
})
