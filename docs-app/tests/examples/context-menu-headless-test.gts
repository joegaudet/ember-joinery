import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness } from '@ember-joinery/test-support'
import ContextMenuHeadless from 'docs-app/examples/context-menu-headless'

module('Example | context-menu-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a right click opens the menu at the pointer, with a submenu', async function (assert) {
    await render(<template><ContextMenuHeadless /></template>)
    const menu = new ContextMenuHarness()
    const area = menu.trigger.getBoundingClientRect()
    await menu.open({ x: area.left + 30, y: area.top + 30 })
    assert.deepEqual(menu.items, ['Back', 'Reload', 'More Tools ›'])
    assert.true(Math.abs(menu.content!.getBoundingClientRect().top - (area.top + 30)) <= 1)
    const more = menu.sub('More Tools ›')
    await more.open()
    assert.deepEqual(more.items, ['Save Page...'])
    await a11yAudit()
    await more.select('Save Page...')
    assert.false(menu.isOpen)
    await a11yAudit()
  })
})
