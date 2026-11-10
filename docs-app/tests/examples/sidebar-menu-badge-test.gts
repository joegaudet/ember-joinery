import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SidebarHarness } from '@ember-joinery/test-support'
import SidebarMenuBadge from 'docs-app/examples/sidebar-menu-badge'

module('Example | sidebar-menu-badge', function (hooks) {
  setupRenderingTest(hooks)

  test('each project shows its count at its end', async function (assert) {
    await render(<template><SidebarMenuBadge /></template>)
    const sidebar = new SidebarHarness()
    assert.strictEqual(sidebar.menuButtons.length, 5)
    assert.deepEqual(sidebar.badges, ['24', '12', '3', '21', '8'])
    const [badge] = sidebar.elements('menu-badge')
    const styles = getComputedStyle(badge!)
    assert.strictEqual(styles.position, 'absolute')
    assert.strictEqual(styles.pointerEvents, 'none', 'a click goes through to the button')
    assert.strictEqual(styles.fontVariantNumeric, 'tabular-nums')
    await a11yAudit()
  })
})
