import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ButtonHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import SonnerDemo from 'docs-app/examples/sonner-demo'

module('Example | sonner-demo', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('the button shows a toast with a description and an Undo action', async function (assert) {
    // The app renders its Toaster once, in its application template; a test renders its own.
    await render(
      <template>
        <SonnerDemo />
        <Toaster />
      </template>,
    )
    const button = new ButtonHarness()
    assert.strictEqual(button.label, 'Show Toast')
    assert.strictEqual(button.variant, 'outline')

    await button.click()
    const toaster = new ToasterHarness()
    const toast = toaster.toast()
    assert.strictEqual(toast.title, 'Event has been created')
    assert.strictEqual(toast.description, 'Sunday, December 03, 2023 at 9:00 AM')
    assert.dom(toast.action).hasText('Undo')
    await a11yAudit()

    await toast.clickAction()
    assert.strictEqual(toaster.count, 0, 'Undo closes it')
  })
})
