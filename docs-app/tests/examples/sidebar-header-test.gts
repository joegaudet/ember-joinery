import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, SidebarHarness } from '@ember-joinery/test-support'
import SidebarHeader from 'docs-app/examples/sidebar-header'

module('Example | sidebar-header', function (hooks) {
  setupRenderingTest(hooks)

  test("the header's menu button opens a workspace menu as wide as itself", async function (assert) {
    await render(<template><SidebarHeader /></template>)
    const sidebar = new SidebarHarness()
    const workspace = sidebar.find(DropdownMenuHarness)
    const button = sidebar.menuButton('Select Workspace')
    assert.strictEqual(workspace.trigger, button.element, 'the menu button is its trigger')
    assert.dom(button.element.closest('[data-slot="sidebar-header"]')).exists()

    await workspace.open()
    assert.true(button.isExpanded)
    assert.deepEqual(workspace.items, ['Acme Inc', 'Acme Corp.'])
    // The test container is drawn at half size, and the menu, in the top layer, isn't: its
    // width is the button's box, which anchoring sets as --jn-anchor-width.
    const content = getComputedStyle(workspace.content!)
    const anchorWidth = Number.parseFloat(content.getPropertyValue('--jn-anchor-width'))
    assert.true(
      Math.abs(anchorWidth - button.element.getBoundingClientRect().width) < 1,
      "anchoring measures the button's box",
    )
    assert.strictEqual(
      Number.parseFloat(content.width),
      Math.max(anchorWidth, 128),
      'w-(--radix-popper-anchor-width): as wide as the button, and min-w-32',
    )
    await a11yAudit()

    await workspace.close()
    await sidebar.toggle()
    assert.false(sidebar.isOpen, 'the trigger in the page closes the sidebar')
    await a11yAudit()
  })
})
