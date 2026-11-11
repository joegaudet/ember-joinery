import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, pressKey } from '@ember-joinery/test-support'
import DropdownMenuHeadless from 'docs-app/examples/dropdown-menu-headless'

module('Example | dropdown-menu-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('ember-primitives’ Menu: items, a separator and a link item, 8px below', async function (assert) {
    await render(<template><DropdownMenuHeadless /></template>)
    const menu = new DropdownMenuHarness()
    assert.dom(menu.trigger).hasAttribute('aria-label', 'Options')
    await menu.openWithKeyboard()
    assert.deepEqual(menu.items, ['Item 1', 'Item 2', 'Item 3'])
    assert.strictEqual(menu.separators, 1)
    assert.strictEqual(menu.highlighted, 'Item 1')
    assert.dom(menu.item('Item 3')).hasTagName('a').hasAttribute('href', '/')
    const trigger = menu.trigger.getBoundingClientRect()
    const content = menu.content!.getBoundingClientRect()
    assert.true(Math.abs(content.top - trigger.bottom - 8) <= 1, '@offsetOptions={{8}}')
    await a11yAudit()
    await pressKey('ArrowDown')
    await pressKey('Enter')
    assert.false(menu.isOpen)
    await a11yAudit()
  })
})
