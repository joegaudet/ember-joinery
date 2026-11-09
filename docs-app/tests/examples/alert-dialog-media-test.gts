import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertDialogHarness, IconHarness } from '@ember-joinery/test-support'
import AlertDialogMedia from 'docs-app/examples/alert-dialog-media'

module('Example | alert-dialog-media', function (hooks) {
  setupRenderingTest(hooks)

  test('an icon above the title, hidden from screen readers', async function (assert) {
    await render(<template><AlertDialogMedia /></template>)
    const alert = new AlertDialogHarness()
    assert.dom(alert.trigger).hasText('Share Project')
    await alert.open()

    assert.strictEqual(alert.label, 'Share this project?')
    const icon = alert.find(IconHarness)
    assert.true(icon.isDecorative)
    assert.dom(icon.element.parentElement).hasAttribute('data-slot', 'alert-dialog-media')
    assert.strictEqual(getComputedStyle(icon.element).width, '24px', 'the media sizes it')
    await a11yAudit()

    await alert.confirm()
    assert.false(alert.isOpen)
    await a11yAudit()
  })
})
