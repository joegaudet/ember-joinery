import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertDialogHarness } from '@ember-joinery/test-support'
import AlertDialogSmall from 'docs-app/examples/alert-dialog-small'

module('Example | alert-dialog-small', function (hooks) {
  setupRenderingTest(hooks)

  test('the small size puts its two buttons side by side', async function (assert) {
    await render(<template><AlertDialogSmall /></template>)
    const alert = new AlertDialogHarness()
    await alert.open()
    assert.dom(alert.content).hasAttribute('data-size', 'sm')
    assert.strictEqual(alert.label, 'Allow accessory to connect?')

    const cancel = alert.cancelButton.getBoundingClientRect()
    const allow = alert.actionButton.getBoundingClientRect()
    assert.strictEqual(Math.round(cancel.top), Math.round(allow.top), 'on one row')
    assert.strictEqual(Math.round(cancel.width), Math.round(allow.width), 'in equal columns')
    await a11yAudit()

    await alert.pressEscape()
    assert.false(alert.isOpen)
    await a11yAudit()
  })
})
