import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertDialogHarness } from '@ember-joinery/test-support'
import AlertDialogBasic from 'docs-app/examples/alert-dialog-basic'

module('Example | alert-dialog-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('a press outside keeps it; Cancel closes it', async function (assert) {
    await render(<template><AlertDialogBasic /></template>)
    const alert = new AlertDialogHarness()
    await alert.open()
    assert.strictEqual(alert.label, 'Are you absolutely sure?')
    assert.strictEqual(alert.cancelButton.textContent?.trim(), 'Cancel')
    assert.strictEqual(alert.actionButton.textContent?.trim(), 'Continue')

    await alert.pressOutside()
    assert.true(alert.isOpen, 'it waits for an answer')
    await a11yAudit()

    await alert.cancel()
    assert.false(alert.isOpen)
    await a11yAudit()
  })
})
