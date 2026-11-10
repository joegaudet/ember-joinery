import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, settled, waitFor } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SidebarHarness } from '@ember-joinery/test-support'
import SidebarRsc from 'docs-app/examples/sidebar-rsc'

module('Example | sidebar-rsc', function (hooks) {
  setupRenderingTest(hooks)

  test('skeletons stand in for the projects while they load', async function (assert) {
    // Not awaited: render() would wait the three seconds the projects take to load.
    void render(<template><SidebarRsc /></template>)
    await waitFor('[data-sidebar="menu-skeleton"]')
    const sidebar = new SidebarHarness()
    assert.strictEqual(sidebar.elements('menu-skeleton').length, 5)
    assert.strictEqual(sidebar.menuButtons.length, 0)

    await settled()
    assert.strictEqual(sidebar.elements('menu-skeleton').length, 0)
    assert.deepEqual(sidebar.menuButtonLabels, [
      'Design Engineering',
      'Sales & Marketing',
      'Travel',
      'Support',
      'Feedback',
    ])
    await a11yAudit()
  })
})
