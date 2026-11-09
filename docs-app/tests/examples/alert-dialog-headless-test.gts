import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertDialogHarness } from '@ember-joinery/test-support'
import AlertDialogHeadless from 'docs-app/examples/alert-dialog-headless'

module('Example | alert-dialog-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('it waits for an answer, with focus on the safe one', async function (assert) {
    await render(<template><AlertDialogHeadless /></template>)
    const alert = new AlertDialogHarness()
    await alert.open()
    assert.strictEqual(alert.role, 'alertdialog')
    assert.dom(alert.cancelButton).isFocused().hasText('Keep it')

    await alert.pressOutside()
    assert.true(alert.isOpen, 'a press outside keeps it')
    await a11yAudit()

    await alert.confirm()
    assert.false(alert.isOpen)
    await a11yAudit()
  })
})
