import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness } from '@ember-joinery/test-support'
import ContextMenuCheckboxes from 'docs-app/examples/context-menu-checkboxes'

module('Example | context-menu-checkboxes', function (hooks) {
  setupRenderingTest(hooks)

  test('three settings, two of them on, each toggled by selecting it', async function (assert) {
    await render(<template><ContextMenuCheckboxes /></template>)
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, ['Show Bookmarks Bar', 'Show Full URLs', 'Show Developer Tools'])
    assert.deepEqual(
      menu.items.map(item => menu.isChecked(item)),
      [true, false, true],
    )
    await a11yAudit()
    await menu.select('Show Full URLs')
    await menu.open()
    assert.true(menu.isChecked('Show Full URLs'))
    await a11yAudit()
  })
})
