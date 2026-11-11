import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DropdownMenuHarness, pressKey } from '@ember-joinery/test-support'
import DropdownMenuDemo from 'docs-app/examples/dropdown-menu-demo'

module('Example | dropdown-menu-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a menu with shortcuts, groups and a submenu, opened by the outline button', async function (assert) {
    await render(<template><DropdownMenuDemo /></template>)
    const menu = new DropdownMenuHarness()
    const button = new ButtonHarness()
    assert.strictEqual(button.label, 'Open')
    assert.strictEqual(button.variant, 'outline')
    assert.strictEqual(menu.trigger, button.element, 'the button is the trigger')

    await menu.open()
    assert.true(menu.isShown)
    assert.strictEqual(getComputedStyle(menu.content!).width, '160px', 'w-40')
    assert.strictEqual(menu.align, 'start')
    assert.deepEqual(menu.labels, ['My Account'])
    assert.deepEqual(menu.items, [
      'Profile',
      'Billing',
      'Settings',
      'Team',
      'Invite users',
      'New Team',
      'GitHub',
      'Support',
      'API',
      'Log out',
    ])
    assert.strictEqual(menu.shortcut('Profile'), '⇧⌘P')
    assert.strictEqual(menu.shortcut('New Team'), '⌘+T')
    assert.strictEqual(menu.shortcut('Log out'), '⇧⌘Q')
    assert.strictEqual(menu.separators, 3)
    assert.true(menu.isDisabled('API'))
    await a11yAudit()

    const invite = menu.sub('Invite users')
    await invite.open()
    assert.deepEqual(invite.items, ['Email', 'Message', 'More...'])
    assert.strictEqual(invite.separators, 1)
    await a11yAudit()

    await menu.pressEscape()
    assert.false(menu.isOpen)
    assert.true(button.isFocused, 'focus is back on the button')

    await menu.openWithKeyboard()
    assert.strictEqual(menu.highlighted, 'Profile')
    await pressKey('End')
    assert.strictEqual(menu.highlighted, 'Log out')
    await pressKey('Enter')
    assert.false(menu.isOpen)
    await a11yAudit()
  })
})
