import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertHarness } from '@ember-joinery/test-support'
import AlertBasic from 'docs-app/examples/alert-basic'

module('Example | alert-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('an icon, a title and a description', async function (assert) {
    await render(<template><AlertBasic /></template>)
    const alert = new AlertHarness()
    assert.strictEqual(alert.title, 'Account updated successfully')
    assert.strictEqual(
      alert.description,
      'Your profile information has been saved. Changes will be reflected immediately.',
    )
    assert.true(alert.hasIcon)
    assert.strictEqual(getComputedStyle(alert.element).maxWidth, '448px', 'max-w-md')
    await a11yAudit()
  })
})
