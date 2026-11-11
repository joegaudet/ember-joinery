import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CommandDialogHarness } from '@ember-joinery/test-support'
import CommandHeadlessDialog from 'docs-app/examples/command-headless-dialog'

module('Example | command-headless-dialog', function (hooks) {
  setupRenderingTest(hooks)

  test('⌘K opens the palette, and choosing a command closes it', async function (assert) {
    await render(<template><CommandHeadlessDialog /></template>)
    const palette = new CommandDialogHarness()
    assert.false(palette.isOpen)

    await palette.pressHotkey('mod+k')
    assert.true(palette.isOpen)
    assert.strictEqual(palette.label, 'Command Palette')
    assert.true(palette.command.hasFocus)
    assert.true(palette.overlay!.classList.contains('bg-black/40'), '@overlayClass')
    await a11yAudit()

    await palette.command.search('theme')
    await palette.command.press('Enter')
    assert.false(palette.isOpen)
    assert.dom('[data-test-ran]').hasText('Toggle Theme')

    await click('button')
    assert.true(palette.isOpen, 'the button opens it too')
    await palette.pressEscape()
    assert.false(palette.isOpen)
    assert.dom('button').isFocused()
    await a11yAudit()
  })
})
