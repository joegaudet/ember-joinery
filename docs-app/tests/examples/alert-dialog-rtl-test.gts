import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { AlertDialogHarness } from '@ember-joinery/test-support'
import AlertDialogRtl from 'docs-app/examples/alert-dialog-rtl'

module('Example | alert-dialog-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, in Arabic', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><AlertDialogRtl /></DirectionProvider>
      </template>,
    )
    const [normal, small] = AlertDialogHarness.findAll()

    await normal!.open()
    assert.strictEqual(normal!.label, 'هل أنت متأكد تمامًا؟')
    assert.strictEqual(getComputedStyle(normal!.content!).direction, 'rtl')
    const cancel = normal!.cancelButton.getBoundingClientRect()
    const action = normal!.actionButton.getBoundingClientRect()
    assert.ok(cancel.left > action.left, 'the buttons run right to left')
    await a11yAudit()
    await normal!.cancel()

    await small!.open()
    assert.dom(small!.content).hasAttribute('data-size', 'sm')
    assert.strictEqual(small!.label, 'السماح للملحق بالاتصال؟')
    await a11yAudit()
    await small!.pressEscape()
    assert.false(small!.isOpen)
    await a11yAudit()
  })
})
