import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, pressKey } from '@ember-joinery/test-support'
import DropdownMenuBasic from 'docs-app/examples/dropdown-menu-basic'

module('Example | dropdown-menu-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('a labelled group, a separator, and a disabled item the keys pass over', async function (assert) {
    await render(<template><DropdownMenuBasic /></template>)
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.deepEqual(menu.labels, ['My Account'])
    assert.deepEqual(menu.items, ['Profile', 'Billing', 'Settings', 'GitHub', 'Support', 'API'])
    assert.strictEqual(menu.separators, 1)
    assert.true(menu.isDisabled('API'))
    await a11yAudit()

    await pressKey('ArrowUp')
    assert.strictEqual(
      menu.highlighted,
      'Support',
      'from the menu, ArrowUp skips the disabled last item',
    )
    await menu.select('GitHub')
    assert.false(menu.isOpen)
    await a11yAudit()
  })
})
