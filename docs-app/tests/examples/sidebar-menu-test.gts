import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SidebarHarness } from '@ember-joinery/test-support'
import SidebarMenu from 'docs-app/examples/sidebar-menu'

module('Example | sidebar-menu', function (hooks) {
  setupRenderingTest(hooks)

  test("the projects' links, each a menu button", async function (assert) {
    await render(<template><SidebarMenu /></template>)
    const sidebar = new SidebarHarness()
    assert.deepEqual(sidebar.groupLabels, ['Projects'])
    assert.deepEqual(sidebar.menuButtonLabels, [
      'Design Engineering',
      'Sales & Marketing',
      'Travel',
      'Support',
      'Feedback',
    ])
    for (const button of sidebar.menuButtons) {
      assert.dom(button.element).hasTagName('a')
      assert.strictEqual(button.href, '#')
      assert.false(button.isActive)
    }
    await a11yAudit()
  })
})
