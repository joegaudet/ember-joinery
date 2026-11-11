import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertHarness } from '@ember-joinery/test-support'
import AlertDemo from 'docs-app/examples/alert-demo'

module('Example | alert-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('two alerts, each with an icon beside its title and description', async function (assert) {
    await render(<template><AlertDemo /></template>)
    const [payment, feature] = AlertHarness.findAll()
    assert.strictEqual(payment!.title, 'Payment successful')
    assert.strictEqual(
      payment!.description,
      'Your payment of $29.99 has been processed. A receipt has been sent to your email address.',
    )
    assert.strictEqual(feature!.title, 'New feature available')
    for (const alert of [payment!, feature!]) {
      assert.strictEqual(alert.variant, 'default')
      assert.strictEqual(alert.role, 'alert')
      assert.true(alert.hasIcon)
      assert.strictEqual(
        getComputedStyle(alert.part('title')).gridColumnStart,
        '2',
        'the title sits beside the icon',
      )
    }
    await a11yAudit()
  })
})
