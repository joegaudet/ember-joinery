import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { IconHarness, SidebarHarness } from '@ember-joinery/test-support'
import SidebarGroup from 'docs-app/examples/sidebar-group'

module('Example | sidebar-group', function (hooks) {
  setupRenderingTest(hooks)

  test('a group: its label, and a menu of buttons with icons', async function (assert) {
    await render(<template><SidebarGroup /></template>)
    const sidebar = new SidebarHarness()
    assert.deepEqual(sidebar.groupLabels, ['Help'])
    assert.deepEqual(sidebar.menuButtonLabels, ['Support', 'Feedback'])
    const support = sidebar.menuButton('Support')
    assert.dom(support.element).hasTagName('button')
    assert.true(new IconHarness({ within: support.element }).isDecorative)
    assert.strictEqual(getComputedStyle(support.element).height, '32px')
    await support.focus()
    assert.true(support.isFocused, 'a menu button takes focus')
    await a11yAudit()
  })
})
