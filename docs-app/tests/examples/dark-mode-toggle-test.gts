import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DropdownMenuHarness, setupColorScheme } from '@ember-joinery/test-support'
import DarkModeToggle from 'docs-app/examples/dark-mode-toggle'

module('Example | dark-mode-toggle', function (hooks) {
  setupRenderingTest(hooks)
  // Each test starts with nothing saved, on a system that prefers light.
  const system = setupColorScheme(hooks, { system: 'light' })

  test('an icon button opens Light, Dark and System; the choice is applied and saved', async function (assert) {
    const html = document.documentElement
    await render(<template><DarkModeToggle /></template>)
    const toggle = new ButtonHarness()
    const menu = new DropdownMenuHarness()
    assert.strictEqual(toggle.label, 'Toggle theme', 'named by its screen-reader text')
    assert.strictEqual(toggle.variant, 'outline')
    assert.strictEqual(toggle.size, 'icon')
    assert.strictEqual(menu.trigger, toggle.element)

    await menu.open()
    assert.deepEqual(menu.items, ['Light', 'Dark', 'System'])
    assert.strictEqual(menu.align, 'end')
    await a11yAudit()

    await menu.select('Dark')
    assert.false(menu.isOpen, 'choosing closes the menu')
    assert.dom(html).hasClass('dark')
    assert.strictEqual(system.stored, 'dark', 'saved for the next visit')

    await menu.open()
    await menu.select('System')
    assert.dom(html).doesNotHaveClass('dark', 'the system prefers light')
    system.setSystem('dark')
    await settled()
    assert.dom(html).hasClass('dark', 'and it follows the system')
    await a11yAudit()
  })
})
