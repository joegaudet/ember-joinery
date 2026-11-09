import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ZoetropeHarness } from '@ember-joinery/test-support'
import ZoetropeCustomControls from 'docs-app/examples/zoetrope-custom-controls'

module('Example | zoetrope-custom-controls', function (hooks) {
  setupRenderingTest(hooks)

  test('its own buttons scroll it, and are disabled at their ends', async function (assert) {
    await render(<template><ZoetropeCustomControls /></template>)
    const zoetrope = new ZoetropeHarness()
    assert.strictEqual(zoetrope.controls, null, 'no default controls')
    assert.dom(zoetrope.leftButton).hasText('<').hasAria('label', 'Scroll left')
    assert.dom(zoetrope.rightButton).hasText('>')
    assert.false(zoetrope.canScrollLeft)

    await zoetrope.scrollRight()
    const scrolled = zoetrope.scrolled
    assert.true(scrolled > 0)
    assert.true(zoetrope.canScrollLeft)
    await zoetrope.scrollLeft()
    assert.true(zoetrope.scrolled < scrolled, 'back a page')
    while (zoetrope.canScrollLeft) await zoetrope.scrollLeft()
    assert.strictEqual(zoetrope.scrolled, 0, 'and back to the start')
    await a11yAudit()
  })
})
