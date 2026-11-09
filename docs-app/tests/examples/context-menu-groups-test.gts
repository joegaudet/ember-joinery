import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness, typeKeys } from '@ember-joinery/test-support'
import ContextMenuGroups from 'docs-app/examples/context-menu-groups'

module('Example | context-menu-groups', function (hooks) {
  setupRenderingTest(hooks)

  test('File and Edit groups with their labels, set apart by separators', async function (assert) {
    await render(<template><ContextMenuGroups /></template>)
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.deepEqual(menu.labels, ['File', 'Edit'])
    assert.deepEqual(menu.items, [
      'New File',
      'Open File',
      'Save',
      'Undo',
      'Redo',
      'Cut',
      'Copy',
      'Paste',
      'Delete',
    ])
    assert.strictEqual(menu.separators, 3)
    assert.dom('[role=group]', menu.content).exists({ count: 4 })
    assert.strictEqual(menu.shortcut('Delete'), '⌫')
    assert.strictEqual(menu.variant('Delete'), 'destructive')
    await a11yAudit()
    await typeKeys('p')
    assert.strictEqual(menu.highlighted, 'Paste')
    await a11yAudit()
  })
})
