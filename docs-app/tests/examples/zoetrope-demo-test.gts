import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ZoetropeHarness } from '@ember-joinery/test-support'
import ZoetropeDemo from 'docs-app/examples/zoetrope-demo'

module('Example | zoetrope-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('sixty cards, a page at a time', async function (assert) {
    await render(<template><ZoetropeDemo /></template>)
    const zoetrope = new ZoetropeHarness()
    assert.dom(zoetrope.header).hasText('Heading')
    assert.strictEqual(zoetrope.items.length, 60)
    assert.false(zoetrope.canScrollLeft, 'at the start')
    assert.true(zoetrope.canScrollRight)

    const [firstInView] = zoetrope.visibleItems
    const inView = zoetrope.visibleItemCount
    await zoetrope.scrollRight()
    assert.true(zoetrope.scrolled > 0, 'it scrolled')
    assert.notStrictEqual(zoetrope.visibleItems[0], firstInView, 'to other cards')
    assert.true(zoetrope.canScrollLeft)

    const scrolled = zoetrope.scrolled
    await zoetrope.scrollLeft()
    assert.true(zoetrope.scrolled < scrolled, 'back a page')
    while (zoetrope.canScrollLeft) await zoetrope.scrollLeft()
    assert.strictEqual(zoetrope.scrolled, 0, 'and back to the start')
    assert.strictEqual(zoetrope.visibleItemCount, inView)
    await a11yAudit()
  })
})
