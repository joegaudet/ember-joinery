import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertDialogHarness } from '@ember-joinery/test-support'
import AlertDialogDemo from 'docs-app/examples/alert-dialog-demo'

module('Example | alert-dialog-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('it asks before it goes on, with focus on Cancel', async function (assert) {
    await render(<template><AlertDialogDemo /></template>)
    const alert = new AlertDialogHarness()
    assert.dom(alert.trigger).hasText('Show Dialog')

    await alert.open()
    assert.strictEqual(alert.role, 'alertdialog')
    assert.strictEqual(alert.label, 'Are you absolutely sure?')
    assert.strictEqual(
      alert.descriptionText,
      'This action cannot be undone. This will permanently delete your account from our servers.',
    )
    assert.dom(alert.cancelButton).isFocused('Cancel, the safe choice, has focus')
    await a11yAudit()

    await alert.confirm()
    assert.false(alert.isOpen, 'Continue closes it')
    assert.dom(alert.trigger).isFocused('and focus goes back to the trigger')
    await a11yAudit()
  })
})
