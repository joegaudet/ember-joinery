import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import ToastHeadless from 'docs-app/examples/toast-headless'

module('Example | toast-headless', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('its own Toaster shows the saving toast, then the outcome', async function (assert) {
    await render(<template><ToastHeadless /></template>)
    await click('button')

    const toaster = new ToasterHarness()
    assert.strictEqual(toaster.label, 'Saving alt+T')
    assert.deepEqual(toaster.positions, ['bottom-center'])
    const toast = toaster.toast()
    assert.true(toast.isLoading)
    assert.strictEqual(toast.title, 'Saving…')

    await toaster.waitForToast('Saved')
    assert.strictEqual(toast.type, 'success', 'the same toast, now the outcome')
    assert.dom(toast.icon!.querySelector('svg')).exists("sonner's own success icon")
    await a11yAudit()
  })
})
