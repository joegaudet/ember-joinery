import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MarkerHarness } from '@ember-joinery/test-support'
import MarkerBorder from 'docs-app/examples/marker-border'

module('Example | marker-border', function (hooks) {
  setupRenderingTest(hooks)

  test('status rows, each with an icon and a line under it', async function (assert) {
    await render(<template><MarkerBorder /></template>)
    const rows = MarkerHarness.findAll()
    assert.deepEqual(
      rows.map(marker => marker.text),
      ['Switched to release-candidate', 'Reviewed 8 related files', 'Opened implementation notes'],
    )
    for (const marker of rows) {
      assert.strictEqual(marker.variant, 'border')
      assert.true(marker.hasIcon)
      const style = getComputedStyle(marker.element)
      assert.strictEqual(style.borderBottomWidth, '1px', 'border-b')
      assert.strictEqual(style.paddingBottom, '8px', 'pb-2')
    }
    await a11yAudit()
  })
})
