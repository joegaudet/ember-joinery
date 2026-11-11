import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ButtonHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import SonnerTypes from 'docs-app/examples/sonner-types'

module('Example | sonner-types', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('a button for each type of toast', async function (assert) {
    await render(
      <template>
        <SonnerTypes />
        <Toaster />
      </template>,
    )
    const buttons = ButtonHarness.findAll()
    assert.deepEqual(
      buttons.map(button => button.label),
      ['Default', 'Success', 'Info', 'Warning', 'Error', 'Promise'],
    )
    for (const button of buttons.slice(0, 5)) await button.click()

    const toaster = new ToasterHarness()
    assert.deepEqual(
      toaster.toasts.map(toast => [toast.type, toast.title]),
      [
        ['error', 'Event has not been created'],
        ['warning', 'Event start time cannot be earlier than 8am'],
        ['info', 'Be at the area 10 minutes before the event time'],
        ['success', 'Event has been created'],
        [null, 'Event has been created'],
      ],
      'newest first',
    )
    assert.ok(toaster.toast().icon, 'each type has its icon')
    await a11yAudit()
  })

  test('the promise toast loads for two seconds, then says the event was created', async function (assert) {
    await render(
      <template>
        <SonnerTypes />
        <Toaster />
      </template>,
    )
    await new ButtonHarness({ index: 5 }).click()
    const toaster = new ToasterHarness()
    const toast = toaster.toast()
    assert.true(toast.isLoading)
    assert.strictEqual(toast.title, 'Loading...')
    await a11yAudit()

    await toaster.waitForToast('Event has been created')
    assert.strictEqual(toast.type, 'success', 'the same toast, now a success')
    assert.strictEqual(toaster.count, 1)
  })
})
