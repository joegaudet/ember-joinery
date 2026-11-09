import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ScrollAreaHarness } from '@ember-joinery/test-support'
import ScrollAreaList from 'docs-app/examples/scroll-area-list'

module('Example | scroll-area-list', function (hooks) {
  setupRenderingTest(hooks)

  test('fifty tags in a 288px area, with a scrollbar while the pointer is over it', async function (assert) {
    await render(<template><ScrollAreaList /></template>)
    const tags = new ScrollAreaHarness()
    assert.strictEqual(tags.element.offsetHeight, 288, 'h-72')
    assert.dom(tags.viewport).containsText('v1.2.0-beta.50')
    assert.strictEqual(tags.scrollbar(), null)

    await tags.hover()
    assert.true(tags.isScrollbarVisible())
    await tags.scrollTo({ top: tags.maxScrollTop })
    assert.ok(tags.thumbOffset() > 0)
    await a11yAudit()
  })
})
