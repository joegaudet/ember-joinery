import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, CommandDialogHarness } from '@ember-joinery/test-support'
import CommandBasic from 'docs-app/examples/command-basic'

module('Example | command-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('a button opens a command menu in a dialog', async function (assert) {
    await render(<template><CommandBasic /></template>)
    const button = new ButtonHarness()
    const palette = new CommandDialogHarness()
    assert.strictEqual(button.text, 'Open Menu')
    assert.false(palette.isOpen)
    await a11yAudit()

    await button.click()
    assert.true(palette.isOpen)
    assert.strictEqual(palette.label, 'Command Palette')
    assert.true(palette.command.hasFocus, 'focus is in the search box')
    assert.deepEqual(palette.command.itemValues, ['Calendar', 'Search Emoji', 'Calculator'])
    await a11yAudit()

    await palette.command.search('calc')
    assert.deepEqual(palette.command.itemValues, ['Calculator'])
    await palette.pressEscape()
    assert.false(palette.isOpen)
    assert.dom(button.element).isFocused('focus goes back to the button')
  })
})
