import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertDialogHarness, IconHarness } from '@ember-joinery/test-support'
import AlertDialogSmallMedia from 'docs-app/examples/alert-dialog-small-media'

module('Example | alert-dialog-small-media', function (hooks) {
  setupRenderingTest(hooks)

  test('small, with a centred icon above its title', async function (assert) {
    await render(<template><AlertDialogSmallMedia /></template>)
    const alert = new AlertDialogHarness()
    await alert.open()
    assert.dom(alert.content).hasAttribute('data-size', 'sm')
    assert.strictEqual(alert.label, 'Allow accessory to connect?')

    const media = alert.find(IconHarness).element.parentElement!.getBoundingClientRect()
    const content = alert.content!.getBoundingClientRect()
    assert.ok(
      Math.abs(media.left + media.width / 2 - (content.left + content.width / 2)) <= 1,
      'the icon is centred',
    )
    await a11yAudit()

    await alert.cancel()
    assert.false(alert.isOpen)
    await a11yAudit()
  })
})
