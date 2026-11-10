import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CollapsibleHarness, SidebarHarness } from '@ember-joinery/test-support'
import SidebarGroupCollapsible from 'docs-app/examples/sidebar-group-collapsible'

module('Example | sidebar-group-collapsible', function (hooks) {
  setupRenderingTest(hooks)

  test("the group's label opens and closes it", async function (assert) {
    await render(<template><SidebarGroupCollapsible /></template>)
    const sidebar = new SidebarHarness()
    const help = sidebar.find(CollapsibleHarness)
    assert.dom(help.trigger).hasTagName('button').hasClass('jn-sidebar-group-label')
    // As upstream's asChild merges them, the CollapsibleTrigger's data-slot wins the label's.
    assert.dom(help.trigger).hasAttribute('data-slot', 'collapsible-trigger')
    assert.dom(help.trigger).hasAttribute('data-sidebar', 'group-label')
    assert.strictEqual(help.label, 'Help')
    assert.true(help.isOpen, 'open to start with')
    assert.deepEqual(sidebar.menuButtonLabels, ['Support', 'Feedback'])
    const chevron = help.trigger.querySelector('svg')!
    assert.strictEqual(getComputedStyle(chevron).rotate, '180deg', 'the chevron points up')

    await help.toggle()
    assert.false(help.isOpen)
    assert.deepEqual(sidebar.menuButtonLabels, [], 'its menu is hidden')
    await a11yAudit()
  })
})
