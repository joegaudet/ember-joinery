import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DialogHarness, tab } from '@ember-joinery/test-support'
import DialogHeadless from 'docs-app/examples/dialog-headless'

module('Example | dialog-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('the behaviour, with your own look', async function (assert) {
    await render(<template><DialogHeadless /></template>)
    const dialog = new DialogHarness()
    await dialog.open()

    assert.true(dialog.isInTopLayer)
    assert.true(dialog.isModal)
    assert.strictEqual(dialog.label, 'Edit profile')
    assert.dom(dialog.content!.querySelector('input')).isFocused('focus moves to the field')
    await tab()
    await tab()
    await tab()
    assert.dom(dialog.content!.querySelector('input')).isFocused('and Tab goes round')
    await a11yAudit()

    await click(dialog.content!.querySelectorAll('button')[1]!)
    assert.false(dialog.isOpen, 'Save is a Close part')
    assert.dom(dialog.trigger).isFocused()
    await a11yAudit()
  })
})
