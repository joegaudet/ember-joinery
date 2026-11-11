import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, IconHarness } from '@ember-joinery/test-support'
import DropdownMenuIcons from 'docs-app/examples/dropdown-menu-icons'

module('Example | dropdown-menu-icons', function (hooks) {
  setupRenderingTest(hooks)

  test('an icon before each item’s text, and a destructive Log out', async function (assert) {
    await render(<template><DropdownMenuIcons /></template>)
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, ['Profile', 'Billing', 'Settings', 'Log out'])
    for (const label of menu.items) {
      const icon = new IconHarness({ within: menu.item(label) })
      assert.true(icon.isDecorative, `${label}'s icon is decorative`)
      assert.strictEqual(getComputedStyle(icon.element).width, '16px', 'size-4')
    }
    assert.strictEqual(menu.variant('Log out'), 'destructive')
    await a11yAudit()
  })
})
