import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness, pressKey } from '@ember-joinery/test-support'
import ContextMenuDemo from 'docs-app/examples/context-menu-demo'

module('Example | context-menu-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a right click on the dashed area opens a browser-like menu there', async function (assert) {
    await render(<template><ContextMenuDemo /></template>)
    const menu = new ContextMenuHarness()
    assert.strictEqual(
      menu.trigger.textContent?.replace(/\s+/g, ' ').trim(),
      'Right click here Long press here',
    )
    assert.strictEqual(getComputedStyle(menu.trigger).borderStyle, 'dashed')

    const area = menu.trigger.getBoundingClientRect()
    await menu.open({ x: area.left + 20, y: area.top + 20 })
    assert.true(menu.isShown)
    assert.strictEqual(getComputedStyle(menu.content!).width, '192px', 'w-48')
    assert.deepEqual(menu.items, [
      'Back',
      'Forward',
      'Reload',
      'More Tools',
      'Show Bookmarks',
      'Show Full URLs',
      'Pedro Duarte',
      'Colm Tuite',
    ])
    assert.deepEqual(menu.labels, ['People'])
    assert.strictEqual(menu.shortcut('Back'), '⌘[')
    assert.true(menu.isDisabled('Forward'))
    assert.true(menu.isChecked('Show Bookmarks'))
    assert.false(menu.isChecked('Show Full URLs'))
    assert.true(menu.isChecked('Pedro Duarte'))
    await a11yAudit()

    const tools = menu.sub('More Tools')
    await tools.open()
    assert.strictEqual(getComputedStyle(tools.content!).width, '176px', 'w-44')
    assert.deepEqual(tools.items, [
      'Save Page...',
      'Create Shortcut...',
      'Name Window...',
      'Developer Tools',
      'Delete',
    ])
    assert.strictEqual(tools.variant('Delete'), 'destructive')
    await a11yAudit()

    await pressKey('Escape')
    assert.false(menu.isOpen)
    await a11yAudit()
  })
})
