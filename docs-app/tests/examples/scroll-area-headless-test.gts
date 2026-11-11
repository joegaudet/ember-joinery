import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ScrollAreaHarness } from '@ember-joinery/test-support'
import ScrollAreaHeadless from 'docs-app/examples/scroll-area-headless'

module('Example | scroll-area-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('the scrollbar shows because the list overflows, and the thumb drags', async function (assert) {
    await render(<template><ScrollAreaHeadless /></template>)
    const releases = new ScrollAreaHarness()
    assert.true(releases.isScrollbarVisible(), '@type="auto": shown without hovering')
    assert.strictEqual(releases.scrollTop, 0)
    await releases.dragThumb('vertical', 40)
    assert.ok(releases.scrollTop > 0, 'dragging the thumb scrolls the list')
    await a11yAudit()
  })
})
