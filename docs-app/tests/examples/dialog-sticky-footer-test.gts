import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DialogHarness } from '@ember-joinery/test-support'
import DialogStickyFooter from 'docs-app/examples/dialog-sticky-footer'

module('Example | dialog-sticky-footer', function (hooks) {
  setupRenderingTest(hooks)

  test('the content scrolls, and the footer stays in view', async function (assert) {
    await render(<template><DialogStickyFooter /></template>)
    const dialog = new DialogHarness()
    await dialog.open()
    assert.strictEqual(dialog.label, 'Sticky Footer')

    const scroller = dialog.content!.querySelector('.overflow-y-auto')!
    assert.ok(scroller.scrollHeight > scroller.clientHeight, 'the text is taller than its box')
    const footer = dialog.content!.querySelector('[data-slot="dialog-footer"]')!
    assert.ok(
      footer.getBoundingClientRect().bottom <= window.innerHeight,
      'the footer is on screen',
    )
    await a11yAudit()

    const close = dialog.findAll(ButtonHarness).find(button => button.text === 'Close')!
    await close.click()
    assert.false(dialog.isOpen, "the footer's Close closes it")
    await a11yAudit()
  })
})
