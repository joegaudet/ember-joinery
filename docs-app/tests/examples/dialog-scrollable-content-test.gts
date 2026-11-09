import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DialogHarness, tab } from '@ember-joinery/test-support'
import DialogScrollableContent from 'docs-app/examples/dialog-scrollable-content'

module('Example | dialog-scrollable-content', function (hooks) {
  setupRenderingTest(hooks)

  test('the text scrolls under the header, and a keyboard can reach it', async function (assert) {
    await render(<template><DialogScrollableContent /></template>)
    const dialog = new DialogHarness()
    await dialog.open()
    const scroller = dialog.content!.querySelector('.overflow-y-auto')!
    assert.ok(scroller.scrollHeight > scroller.clientHeight, 'it scrolls')
    assert.dom(scroller).isFocused('the scrolling text takes focus first')
    await tab()
    assert.dom(dialog.closeButton).isFocused('then the close button')
    await a11yAudit()

    await dialog.close()
    assert.false(dialog.isOpen)
    await a11yAudit()
  })
})
