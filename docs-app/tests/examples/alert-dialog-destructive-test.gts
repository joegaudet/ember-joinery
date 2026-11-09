import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertDialogHarness, ButtonHarness } from '@ember-joinery/test-support'
import AlertDialogDestructive from 'docs-app/examples/alert-dialog-destructive'

module('Example | alert-dialog-destructive', function (hooks) {
  setupRenderingTest(hooks)

  test('a destructive trigger and action, and a link in the description', async function (assert) {
    await render(<template><AlertDialogDestructive /></template>)
    const alert = new AlertDialogHarness()
    await alert.open()
    assert.strictEqual(alert.label, 'Delete chat?')
    assert.dom('a', alert.description!).hasText('Settings')

    // The trigger, then the content's two buttons, all Buttons.
    const [trigger, cancel, remove] = alert.findAll(ButtonHarness)
    assert.strictEqual(trigger!.label, 'Delete Chat')
    assert.strictEqual(trigger!.variant, 'destructive')
    assert.strictEqual(cancel!.variant, 'outline')
    assert.strictEqual(remove!.variant, 'destructive')
    assert.strictEqual(remove!.label, 'Delete')
    await a11yAudit()

    await remove!.click()
    assert.false(alert.isOpen)
    await a11yAudit()
  })
})
