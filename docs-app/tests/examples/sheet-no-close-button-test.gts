import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SheetHarness } from '@ember-joinery/test-support'
import SheetNoCloseButton from 'docs-app/examples/sheet-no-close-button'

module('Example | sheet-no-close-button', function (hooks) {
  setupRenderingTest(hooks)

  test('a press outside closes it', async function (assert) {
    await render(<template><SheetNoCloseButton /></template>)
    const sheet = new SheetHarness()
    assert.dom(sheet.trigger).hasText('Open Sheet')
    await sheet.open()
    assert.strictEqual(sheet.side, 'right')
    assert.strictEqual(sheet.closeButton, null)
    assert.strictEqual(sheet.label, 'No Close Button')
    await a11yAudit()

    await sheet.pressOutside()
    assert.false(sheet.isOpen)
    assert.dom(sheet.trigger).isFocused()
    await a11yAudit()
  })
})
