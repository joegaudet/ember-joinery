import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness, IconHarness } from '@ember-joinery/test-support'
import ContextMenuIcons from 'docs-app/examples/context-menu-icons'

module('Example | context-menu-icons', function (hooks) {
  setupRenderingTest(hooks)

  test('Copy, Cut and Paste with their icons, and Delete', async function (assert) {
    await render(<template><ContextMenuIcons /></template>)
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, ['Copy', 'Cut', 'Paste', 'Delete'])
    for (const label of menu.items) {
      assert.true(new IconHarness({ within: menu.item(label) }).isDecorative, `${label}'s icon`)
    }
    assert.strictEqual(menu.variant('Delete'), 'destructive')
    await a11yAudit()
  })
})
