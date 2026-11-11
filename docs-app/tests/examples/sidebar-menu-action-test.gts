import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, SidebarHarness } from '@ember-joinery/test-support'
import SidebarMenuAction from 'docs-app/examples/sidebar-menu-action'

module('Example | sidebar-menu-action', function (hooks) {
  setupRenderingTest(hooks)

  test("each project's action opens its menu to the right, and its item stays highlighted", async function (assert) {
    await render(<template><SidebarMenuAction /></template>)
    const sidebar = new SidebarHarness()
    const menus = sidebar.findAll(DropdownMenuHarness)
    assert.strictEqual(menus.length, 5, 'one menu for each project')
    const travel = menus[2]!
    assert.dom(travel.trigger).hasClass('jn-sidebar-menu-action').hasText('More')
    const button = sidebar.menuButton('Travel').element
    const before = getComputedStyle(button).backgroundColor

    await travel.openWithKeyboard()
    assert.true(travel.isOpen)
    assert.strictEqual(travel.side, 'right')
    assert.strictEqual(travel.align, 'start')
    assert.deepEqual(travel.items, ['Edit Project', 'Delete Project'])
    assert.notStrictEqual(
      getComputedStyle(button).backgroundColor,
      before,
      'the item has an open menu: group-has-[[data-state=open]]/menu-item:bg-sidebar-accent',
    )
    await a11yAudit()

    await travel.pressEscape()
    assert.false(travel.isOpen)
    assert.dom(travel.trigger).isFocused('focus goes back to the action')
  })
})
