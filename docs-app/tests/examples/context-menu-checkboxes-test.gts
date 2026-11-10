import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness } from '@ember-joinery/test-support'
import ContextMenuCheckboxes from 'docs-app/examples/context-menu-checkboxes'

module('Example | context-menu-checkboxes', function (hooks) {
  setupRenderingTest(hooks)

  test('three settings, unchecked, which stay so as upstream’s do', async function (assert) {
    await render(<template><ContextMenuCheckboxes /></template>)
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, ['Show Bookmarks Bar', 'Show Full URLs', 'Show Developer Tools'])
    assert.deepEqual(
      menu.items.map(item => menu.role(item)),
      ['menuitemcheckbox', 'menuitemcheckbox', 'menuitemcheckbox'],
    )
    assert.deepEqual(
      menu.items.map(item => menu.isChecked(item)),
      [false, false, false],
    )
    await a11yAudit()

    // Nothing keeps their state, so selecting one closes the menu and leaves it unchecked.
    await menu.select('Show Full URLs')
    assert.false(menu.isOpen)
    await menu.open()
    assert.false(menu.isChecked('Show Full URLs'))
    await a11yAudit()
  })
})
