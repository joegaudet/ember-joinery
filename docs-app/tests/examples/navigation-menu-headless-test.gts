import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { NavigationMenuHarness } from '@ember-joinery/test-support'
import NavigationMenuHeadless from 'docs-app/examples/navigation-menu-headless'

module('Example | navigation-menu-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('the headless navigation menu: a viewport sized to the open content, and an indicator', async function (assert) {
    await render(<template><NavigationMenuHeadless /></template>)
    const nav = new NavigationMenuHarness()
    assert.deepEqual(nav.triggerLabels, ['Learn', 'Overview'])
    assert.deepEqual(nav.listLinks, ['GitHub'])
    const learn = nav.item('Learn')
    await learn.open()
    assert.deepEqual(learn.links, ['Guides', 'Tutorials'])
    assert.strictEqual(nav.viewportSize!.width, 256, 'as wide as the content (w-64)')
    assert.dom(nav.indicator).hasAttribute('data-state', 'visible')
    await a11yAudit()
    await nav.item('Overview').open()
    assert.strictEqual(nav.viewportSize!.width, 320, 'then as wide as the next (w-80)')
    await a11yAudit()
  })
})
