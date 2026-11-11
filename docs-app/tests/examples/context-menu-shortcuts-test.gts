import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness } from '@ember-joinery/test-support'
import ContextMenuShortcuts from 'docs-app/examples/context-menu-shortcuts'

module('Example | context-menu-shortcuts', function (hooks) {
  setupRenderingTest(hooks)

  test('every item shows its shortcut', async function (assert) {
    await render(<template><ContextMenuShortcuts /></template>)
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, ['Back', 'Forward', 'Reload', 'Save', 'Save As...'])
    assert.deepEqual(
      menu.items.map(item => menu.shortcut(item)),
      ['⌘[', '⌘]', '⌘R', '⌘S', '⇧⌘S'],
    )
    assert.strictEqual(menu.separators, 1)
    await a11yAudit()
  })
})
