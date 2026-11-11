import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness } from '@ember-joinery/test-support'
import DropdownMenuShortcuts from 'docs-app/examples/dropdown-menu-shortcuts'

module('Example | dropdown-menu-shortcuts', function (hooks) {
  setupRenderingTest(hooks)

  test('each item shows its shortcut at its end', async function (assert) {
    await render(<template><DropdownMenuShortcuts /></template>)
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, ['Profile', 'Billing', 'Settings', 'Log out'])
    assert.deepEqual(
      menu.items.map(item => menu.shortcut(item)),
      ['⇧⌘P', '⌘B', '⌘S', '⇧⌘Q'],
    )
    const item = menu.item('Billing').getBoundingClientRect()
    const shortcut = menu.item('Billing').querySelector('[data-slot$="shortcut"]')!
    assert.true(
      Math.abs(shortcut.getBoundingClientRect().right - (item.right - 6)) <= 1,
      'at the end of its item',
    )
    await a11yAudit()
  })
})
