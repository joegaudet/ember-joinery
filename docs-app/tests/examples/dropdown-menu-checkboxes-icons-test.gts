import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, pressKey } from '@ember-joinery/test-support'
import DropdownMenuCheckboxesIcons from 'docs-app/examples/dropdown-menu-checkboxes-icons'

module('Example | dropdown-menu-checkboxes-icons', function (hooks) {
  setupRenderingTest(hooks)

  test('notification preferences, each with an icon and a check while on', async function (assert) {
    await render(<template><DropdownMenuCheckboxesIcons /></template>)
    const menu = new DropdownMenuHarness()
    await menu.openWithKeyboard()
    assert.strictEqual(menu.label, 'Notifications')
    assert.deepEqual(menu.labels, ['Notification Preferences'])
    assert.deepEqual(menu.items, ['Email notifications', 'SMS notifications', 'Push notifications'])
    assert.deepEqual(
      menu.items.map(item => menu.isChecked(item)),
      [true, false, true],
    )
    assert.dom('svg', menu.item('SMS notifications')).exists({ count: 1 }, 'its icon, no check')
    assert.dom('svg', menu.item('Email notifications')).exists({ count: 2 }, 'its icon and a check')
    await a11yAudit()

    await pressKey('ArrowDown')
    await pressKey('Enter')
    await menu.open()
    assert.true(menu.isChecked('SMS notifications'), 'Enter toggled it')
    await a11yAudit()
  })
})
