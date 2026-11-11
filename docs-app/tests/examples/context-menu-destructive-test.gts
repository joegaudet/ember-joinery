import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness } from '@ember-joinery/test-support'
import ContextMenuDestructive from 'docs-app/examples/context-menu-destructive'

module('Example | context-menu-destructive', function (hooks) {
  setupRenderingTest(hooks)

  test('Delete is destructive, after a separator', async function (assert) {
    await render(<template><ContextMenuDestructive /></template>)
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, ['Edit', 'Share', 'Delete'])
    assert.strictEqual(menu.separators, 1)
    assert.strictEqual(menu.variant('Delete'), 'destructive')
    await a11yAudit()
  })
})
