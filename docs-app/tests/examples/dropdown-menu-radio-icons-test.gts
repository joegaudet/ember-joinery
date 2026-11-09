import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, typeKeys, pressKey } from '@ember-joinery/test-support'
import DropdownMenuRadioIcons from 'docs-app/examples/dropdown-menu-radio-icons'

module('Example | dropdown-menu-radio-icons', function (hooks) {
  setupRenderingTest(hooks)

  test('a payment method, chosen from radio items with icons', async function (assert) {
    await render(<template><DropdownMenuRadioIcons /></template>)
    const menu = new DropdownMenuHarness()
    await menu.openWithKeyboard()
    assert.strictEqual(getComputedStyle(menu.content!).minWidth, '224px', 'min-w-56')
    assert.deepEqual(menu.labels, ['Select Payment Method'])
    assert.deepEqual(menu.items, ['Credit Card', 'PayPal', 'Bank Transfer'])
    assert.true(menu.isChecked('Credit Card'))
    await a11yAudit()

    await typeKeys('b')
    assert.strictEqual(menu.highlighted, 'Bank Transfer', 'typing goes to it')
    await pressKey('Enter')
    await menu.open()
    assert.true(menu.isChecked('Bank Transfer'))
    assert.false(menu.isChecked('Credit Card'))
    await a11yAudit()
  })
})
