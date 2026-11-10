import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SidebarHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import SidebarGroupAction from 'docs-app/examples/sidebar-group-action'

module('Example | sidebar-group-action', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test("the group's action shows a toast", async function (assert) {
    await render(<template><SidebarGroupAction /></template>)
    const sidebar = new SidebarHarness()
    assert.deepEqual(sidebar.groupLabels, ['Projects'])
    const action = sidebar.part('group-action')
    assert.dom(action).hasTagName('button').hasAttribute('title', 'Add Project')
    assert.dom(action).hasText('Add Project', 'named by its hidden label')
    assert.deepEqual(sidebar.menuButtonLabels, [
      'Design Engineering',
      'Sales & Marketing',
      'Travel',
    ])

    await click(action)
    const toast = new ToasterHarness().toast()
    assert.strictEqual(toast.title, 'You clicked the group action!')
    assert.strictEqual(toast.position, 'bottom-left')
    assert.dom(toast.element).hasClass('ml-[160px]', "the Toaster's toastOptions className")
    await a11yAudit()
  })
})
