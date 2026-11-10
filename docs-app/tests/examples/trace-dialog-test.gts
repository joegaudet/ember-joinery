import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DialogHarness, TraceHarness, TraceLineHarness } from '@ember-joinery/test-support'
import TraceDialog from 'docs-app/examples/trace-dialog'

module('Example | trace-dialog', function (hooks) {
  setupRenderingTest(hooks)

  test("a row that opens a dialog of results; the dialog's trigger is the tab stop", async function (assert) {
    await render(<template><TraceDialog /></template>)
    const line = new TraceLineHarness()
    assert.strictEqual(line.title, 'Searched the web for cache keys')
    const dialog = new DialogHarness()
    assert.strictEqual(line.control, dialog.trigger, 'the line sits in the dialog trigger')
    await line.click()
    assert.true(dialog.isOpen)
    assert.strictEqual(dialog.label, 'Searched the web for cache keys')
    const results = new TraceHarness({ within: dialog })
    assert.strictEqual(results.lines.length, 3)
    assert.true(results.lines.every(result => result.opensInNewTab))
    await a11yAudit()
    await dialog.pressEscape()
    assert.false(dialog.isOpen)
    assert.dom(dialog.trigger).isFocused('focus returns to the row')
    await a11yAudit()
  })
})
