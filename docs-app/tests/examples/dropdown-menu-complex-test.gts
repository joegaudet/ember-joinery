import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness } from '@ember-joinery/test-support'
import DropdownMenuComplex from 'docs-app/examples/dropdown-menu-complex'

module('Example | dropdown-menu-complex', function (hooks) {
  setupRenderingTest(hooks)

  test('groups, icons, checkbox items and three levels of submenus', async function (assert) {
    await render(<template><DropdownMenuComplex /></template>)
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.deepEqual(menu.labels, ['File', 'View', 'Account'])
    assert.deepEqual(menu.items, [
      'New File',
      'New Folder',
      'Open Recent',
      'Save',
      'Export',
      'Show Sidebar',
      'Show Status Bar',
      'Theme',
      'Profile',
      'Billing',
      'Settings',
      'Help & Support',
      'Documentation',
      'Sign Out',
    ])
    assert.true(menu.isChecked('Show Sidebar'))
    assert.false(menu.isChecked('Show Status Bar'))
    assert.strictEqual(menu.variant('Sign Out'), 'destructive')
    await a11yAudit()

    const recent = menu.sub('Open Recent')
    await recent.open()
    assert.deepEqual(recent.labels, ['Recent Projects'])
    assert.deepEqual(recent.items, ['Project Alpha', 'Project Beta', 'More Projects', 'Browse...'])
    const more = recent.sub('More Projects')
    await more.open()
    assert.deepEqual(more.items, ['Project Gamma', 'Project Delta'])

    const theme = menu.sub('Theme')
    await theme.open()
    assert.false(recent.isOpen, 'another submenu closes the first')
    assert.deepEqual(theme.items, ['Light', 'Dark', 'System'])
    assert.true(theme.isChecked('Light'))
    await theme.select('Dark')
    await menu.open()
    await menu.sub('Theme').open()
    assert.true(menu.sub('Theme').isChecked('Dark'))

    const settings = menu.sub('Settings')
    await settings.open()
    const notifications = settings.sub('Notifications')
    await notifications.open()
    assert.deepEqual(notifications.labels, ['Notification Types'])
    assert.true(notifications.isChecked('Push Notifications'))
    assert.true(notifications.isChecked('Email Notifications'), 'it shares Show Sidebar’s state')
    await a11yAudit()
  })
})
