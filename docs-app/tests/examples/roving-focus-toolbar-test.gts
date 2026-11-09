import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, focus, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { RovingFocusGroupHarness, tab } from '@ember-joinery/test-support'
import RovingFocusToolbar from 'docs-app/examples/roving-focus-toolbar'

/** The formatting toolbar: a roving focus group whose items are toggle buttons. */
class FormattingToolbar extends RovingFocusGroupHarness {
  static named = 'formatting'

  isPressed(id: string) {
    return this.item(id).getAttribute('aria-pressed') === 'true'
  }

  async toggle(id: string) {
    await click(this.item(id))
  }
}

module('Example | roving-focus-toolbar', function (hooks) {
  setupRenderingTest(hooks)

  test('one tab stop, arrows between the buttons, and round from the ends', async function (assert) {
    await render(
      <template>
        <button type="button" id="before">Before</button>
        <RovingFocusToolbar />
      </template>,
    )
    const toolbar = new FormattingToolbar()
    assert.deepEqual(toolbar.ids, ['bold', 'italic', 'underline', 'start', 'center', 'end'])

    await focus('#before')
    await tab()
    assert.strictEqual(toolbar.focused, 'bold', 'Tab enters on the first button')
    await toolbar.press('ArrowRight')
    assert.strictEqual(toolbar.focused, 'italic')
    await toolbar.press('End')
    assert.strictEqual(toolbar.focused, 'end')
    await toolbar.press('ArrowRight')
    assert.strictEqual(toolbar.focused, 'bold', 'it loops')
    await toolbar.press('ArrowLeft')
    assert.strictEqual(toolbar.focused, 'end')
    await toolbar.press('Home')
    assert.strictEqual(toolbar.focused, 'bold')

    await toolbar.toggle('italic')
    assert.true(toolbar.isPressed('italic'))
    assert.strictEqual(toolbar.tabStop, 'italic', 'a click moves the tab stop too')
    await a11yAudit()
  })

  test('right to left, the arrows follow the reading direction', async function (assert) {
    await render(
      <template>
        <div dir="rtl"><RovingFocusToolbar /></div>
      </template>,
    )
    const toolbar = new FormattingToolbar()
    await toolbar.focus('bold')
    await toolbar.press('ArrowLeft')
    assert.strictEqual(toolbar.focused, 'italic', 'left is forward')
    await toolbar.press('ArrowRight')
    assert.strictEqual(toolbar.focused, 'bold')
    await a11yAudit()
  })
})
