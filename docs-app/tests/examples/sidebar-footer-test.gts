import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, SidebarHarness } from '@ember-joinery/test-support'
import SidebarFooter from 'docs-app/examples/sidebar-footer'

module('Example | sidebar-footer', function (hooks) {
  setupRenderingTest(hooks)

  test("the footer's menu button opens the account menu above it", async function (assert) {
    await render(<template><SidebarFooter /></template>)
    const sidebar = new SidebarHarness()
    const account = sidebar.find(DropdownMenuHarness)
    const button = sidebar.menuButton('Username')
    assert.dom(button.element.closest('[data-slot="sidebar-footer"]')).exists()
    const footer = button.element.closest('[data-slot="sidebar-footer"]')!
    const inner = footer.closest('[data-slot="sidebar-inner"]')!
    assert.strictEqual(
      Math.round(footer.getBoundingClientRect().bottom),
      Math.round(inner.getBoundingClientRect().bottom - 0),
      'the footer sits at the bottom of the sidebar',
    )

    await account.open()
    assert.strictEqual(account.side, 'top')
    assert.deepEqual(account.items, ['Account', 'Billing', 'Sign out'])
    await a11yAudit()
  })
})
