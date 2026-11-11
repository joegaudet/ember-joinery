import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SidebarHarness } from '@ember-joinery/test-support'
import SidebarMenuSub from 'docs-app/examples/sidebar-menu-sub'

module('Example | sidebar-menu-sub', function (hooks) {
  setupRenderingTest(hooks)

  test("each section's links, in a submenu under it", async function (assert) {
    await render(<template><SidebarMenuSub /></template>)
    const sidebar = new SidebarHarness()
    assert.deepEqual(sidebar.menuButtonLabels, [
      'Getting Started',
      'Build Your Application',
      'API Reference',
      'Architecture',
    ])
    assert.strictEqual(sidebar.menuSubButtons.length, 25)
    const fetching = sidebar.menuSubButton('Data Fetching')
    assert.dom(fetching.element).hasTagName('a')
    assert.strictEqual(fetching.size, 'md')
    assert.false(fetching.isActive, "upstream's data marks it, and never passes it on")
    const sub = fetching.element.closest('[data-slot="sidebar-menu-sub"]')!
    assert.strictEqual(getComputedStyle(sub).borderLeftWidth, '1px', 'a line at its start')
    assert.strictEqual(getComputedStyle(fetching.element).height, '28px', 'h-7')
    await a11yAudit()
  })
})
