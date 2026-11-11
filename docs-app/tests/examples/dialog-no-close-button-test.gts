import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DialogHarness } from '@ember-joinery/test-support'
import DialogNoCloseButton from 'docs-app/examples/dialog-no-close-button'

module('Example | dialog-no-close-button', function (hooks) {
  setupRenderingTest(hooks)

  test('no close button: Escape or a press outside closes it', async function (assert) {
    await render(<template><DialogNoCloseButton /></template>)
    const dialog = new DialogHarness()
    await dialog.open()
    assert.strictEqual(dialog.closeButton, null)
    assert.strictEqual(dialog.label, 'No Close Button')
    assert.true(dialog.hasFocus, 'focus is inside, on the dialog itself')
    await a11yAudit()

    await dialog.pressEscape()
    assert.false(dialog.isOpen)
    assert.dom(dialog.trigger).isFocused()

    await dialog.open()
    await dialog.pressOutside()
    assert.false(dialog.isOpen)
    await a11yAudit()
  })
})
