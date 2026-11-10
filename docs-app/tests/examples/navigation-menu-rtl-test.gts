import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { focus, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { NavigationMenuHarness, pressKey } from '@ember-joinery/test-support'
import NavigationMenuRtl from 'docs-app/examples/navigation-menu-rtl'

module('Example | navigation-menu-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, right to left: ArrowLeft moves on, and contents slide the other way', async function (assert) {
    await render(
      <template>
        <div dir="rtl"><NavigationMenuRtl /></div>
      </template>,
    )
    const nav = new NavigationMenuHarness()
    assert.deepEqual(nav.triggerLabels, ['البدء', 'المكونات'])
    await focus(nav.trigger('البدء'))
    await pressKey('ArrowLeft')
    assert.strictEqual(nav.focused, 'المكونات')
    const start = nav.item('البدء')
    await start.open()
    assert.strictEqual(start.links.length, 3)
    await a11yAudit()
    const components = nav.item('المكونات')
    await components.open()
    assert.strictEqual(components.motion, 'from-start', 'from the left, where its trigger is')
    assert.strictEqual(components.links.length, 6)
    await a11yAudit()
  })
})
