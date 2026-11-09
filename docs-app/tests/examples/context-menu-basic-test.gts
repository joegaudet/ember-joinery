import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness, pressKey } from '@ember-joinery/test-support'
import ContextMenuBasic from 'docs-app/examples/context-menu-basic'

module('Example | context-menu-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('Back, a disabled Forward, and Reload', async function (assert) {
    await render(<template><ContextMenuBasic /></template>)
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, ['Back', 'Forward', 'Reload'])
    assert.true(menu.isDisabled('Forward'))
    await a11yAudit()
    await pressKey('ArrowDown')
    await pressKey('ArrowDown')
    assert.strictEqual(menu.highlighted, 'Reload', 'past Forward')
    await pressKey('Enter')
    assert.false(menu.isOpen)
    await a11yAudit()
  })
})
