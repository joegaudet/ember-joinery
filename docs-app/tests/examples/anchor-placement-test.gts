import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, select } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, placementOf, setupAnchorFallback } from '@ember-joinery/test-support'
import AnchorPlacement from 'docs-app/examples/anchor-placement'

/** The example: two selects, the anchor button, and the label anchored to it. */
class AnchorDemoHarness extends Harness {
  static component = 'anchor-demo'

  get anchor() {
    return this.part('anchor')
  }

  get label() {
    return this.part('label')
  }

  /** Where the label ended up, from its `data-side` and `data-align`. */
  get placement() {
    return placementOf(this.label)
  }

  async place(side: string, align: string) {
    await select(this.part('side'), side)
    await select(this.part('align'), align)
  }
}

function placementTests() {
  test('the label follows the side and alignment chosen', async function (assert) {
    await render(<template><AnchorPlacement /></template>)
    const demo = new AnchorDemoHarness()
    assert.deepEqual(demo.placement, { side: 'top', align: 'center' })
    assert.true(
      demo.label.getBoundingClientRect().bottom <= demo.anchor.getBoundingClientRect().top,
    )

    await demo.place('bottom', 'start')
    assert.deepEqual(demo.placement, { side: 'bottom', align: 'start' })
    const label = demo.label.getBoundingClientRect()
    const anchor = demo.anchor.getBoundingClientRect()
    assert.true(label.top >= anchor.bottom, 'below the anchor')
    assert.true(Math.abs(label.left - anchor.left) <= 1, 'lined up with its left edge')
    await a11yAudit()
  })
}

module('Example | anchor-placement', function (hooks) {
  setupRenderingTest(hooks)
  placementTests()
})

// The same test, with CSS anchor positioning turned off, as browsers without it run it.
module('Example | anchor-placement, Floating UI', function (hooks) {
  setupRenderingTest(hooks)
  setupAnchorFallback(hooks)
  placementTests()
})
