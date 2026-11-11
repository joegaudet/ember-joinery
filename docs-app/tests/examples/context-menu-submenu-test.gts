import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness } from '@ember-joinery/test-support'
import ContextMenuSubmenu from 'docs-app/examples/context-menu-submenu'

module('Example | context-menu-submenu', function (hooks) {
  setupRenderingTest(hooks)

  test('More Tools opens beside the menu', async function (assert) {
    await render(<template><ContextMenuSubmenu /></template>)
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, ['Copy', 'Cut', 'More Tools'])
    assert.strictEqual(menu.shortcut('Copy'), '⌘C')
    const tools = menu.sub('More Tools')
    await tools.open()
    assert.strictEqual(tools.side, 'right')
    assert.deepEqual(tools.items, [
      'Save Page...',
      'Create Shortcut...',
      'Name Window...',
      'Developer Tools',
      'Delete',
    ])
    assert.strictEqual(tools.separators, 2)
    await a11yAudit()
    await tools.select('Developer Tools')
    assert.false(menu.isOpen)
    await a11yAudit()
  })
})
