import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MarkerHarness, SpinnerHarness } from '@ember-joinery/test-support'
import MarkerStatus from 'docs-app/examples/marker-status'

module('Example | marker-status', function (hooks) {
  setupRenderingTest(hooks)

  test('two status markers, each with a spinner, one as a separator', async function (assert) {
    await render(<template><MarkerStatus /></template>)
    const [compacting, running] = MarkerHarness.findAll()
    for (const marker of [compacting!, running!]) {
      assert.true(marker.isStatus, `${marker.text}: role="status"`)
      assert.true(marker.find(SpinnerHarness).exists, 'a spinner in its icon')
    }
    assert.strictEqual(compacting!.text, 'Compacting conversation')
    assert.strictEqual(running!.text, 'Running tests')
    assert.strictEqual(running!.variant, 'separator')
    await a11yAudit()
  })
})
