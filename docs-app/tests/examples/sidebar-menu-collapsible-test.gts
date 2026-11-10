import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SidebarHarness } from '@ember-joinery/test-support'
import SidebarMenuCollapsible from 'docs-app/examples/sidebar-menu-collapsible'

module('Example | sidebar-menu-collapsible', function (hooks) {
  setupRenderingTest(hooks)

  test('each section opens and closes its submenu; the first starts open', async function (assert) {
    await render(<template><SidebarMenuCollapsible /></template>)
    const sidebar = new SidebarHarness()
    const [started, build] = sidebar.menuButtons
    assert.strictEqual(started!.label, 'Getting Started')
    assert.true(started!.isExpanded)
    assert.false(build!.isExpanded)
    assert.deepEqual(sidebar.menuSubButtonLabels, ['Installation', 'Project Structure'])
    assert.strictEqual(sidebar.elements('menu-item').length, 4, 'each collapsible is a menu item')
    assert.dom(started!.element.closest('li')).hasClass('group/collapsible')

    await build!.click()
    assert.true(build!.isExpanded)
    assert.strictEqual(sidebar.menuSubButtons.length, 14)
    await started!.click()
    assert.false(started!.isExpanded)
    assert.strictEqual(sidebar.menuSubButtons.length, 12)
    await a11yAudit()
  })
})
