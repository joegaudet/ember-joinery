import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, SidebarHarness } from '@ember-joinery/test-support'
import SidebarControlled from 'docs-app/examples/sidebar-controlled'

module('Example | sidebar-controlled', function (hooks) {
  setupRenderingTest(hooks)

  test('a button of its own opens and closes the sidebar, through @open', async function (assert) {
    await render(<template><SidebarControlled /></template>)
    const sidebar = new SidebarHarness()
    const button = new ButtonHarness({ within: sidebar.inset! })
    assert.true(sidebar.isOpen)
    assert.strictEqual(button.label, 'Close Sidebar')

    await button.click()
    assert.false(sidebar.isOpen)
    assert.strictEqual(button.label, 'Open Sidebar')
    await a11yAudit()

    await sidebar.pressShortcut()
    assert.true(sidebar.isOpen, 'the shortcut tells @onOpenChange, which opens it')
    assert.strictEqual(button.label, 'Close Sidebar')
    await a11yAudit()
  })
})
