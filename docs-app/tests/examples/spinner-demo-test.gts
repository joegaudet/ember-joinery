import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ItemHarness, SpinnerHarness } from '@ember-joinery/test-support'
import SpinnerDemo from 'docs-app/examples/spinner-demo'

module('Example | spinner-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a payment processing, in a muted item', async function (assert) {
    await render(<template><SpinnerDemo /></template>)
    const item = new ItemHarness()
    assert.strictEqual(item.variant, 'muted')
    assert.strictEqual(item.title, 'Processing payment...')
    assert.strictEqual(item.text, 'Processing payment... $100.00')
    const spinner = item.find(SpinnerHarness)
    assert.strictEqual(spinner.label, 'Loading')
    assert.strictEqual(spinner.role, 'status')
    assert.strictEqual(
      getComputedStyle(item.element).borderTopLeftRadius,
      '16px',
      '[--radius:1rem] rounds it more',
    )
    await a11yAudit()
  })
})
