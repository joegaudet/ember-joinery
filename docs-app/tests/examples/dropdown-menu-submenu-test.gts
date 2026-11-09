import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, pressKey } from '@ember-joinery/test-support'
import DropdownMenuSubmenu from 'docs-app/examples/dropdown-menu-submenu'

module('Example | dropdown-menu-submenu', function (hooks) {
  setupRenderingTest(hooks)

  test('a submenu with a submenu of its own, by pointer and keyboard', async function (assert) {
    await render(<template><DropdownMenuSubmenu /></template>)
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, ['Team', 'Invite users', 'New Team'])

    const invite = menu.sub('Invite users')
    await invite.open()
    assert.deepEqual(invite.items, ['Email', 'Message', 'More options', 'Advanced...'])
    assert.strictEqual(invite.side, 'right')
    const more = invite.sub('More options')
    await more.open()
    assert.deepEqual(more.items, ['Calendly', 'Slack', 'Webhook'])
    await a11yAudit()

    await more.select('Slack')
    assert.false(menu.isOpen, 'selecting deep inside closes the whole menu')

    await menu.openWithKeyboard()
    await pressKey('ArrowDown')
    await pressKey('ArrowRight')
    assert.strictEqual(invite.highlighted, 'Email')
    await pressKey('ArrowLeft')
    assert.false(invite.isOpen)
    assert.strictEqual(menu.highlighted, 'Invite users')
    await a11yAudit()
  })
})
