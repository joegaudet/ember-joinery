import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ScrollAreaHarness } from '@ember-joinery/test-support'
import ScrollAreaHorizontalDemo from 'docs-app/examples/scroll-area-horizontal-demo'

module('Example | scroll-area-horizontal-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('three photos in a row, scrolled across with the horizontal scrollbar', async function (assert) {
    await render(<template><ScrollAreaHorizontalDemo /></template>)
    const works = new ScrollAreaHarness()
    assert.dom('figure', works.viewport).exists({ count: 3 })
    assert.dom('img', works.viewport).hasAttribute('alt', 'Photo by Ornella Binni')
    assert.dom('figcaption', works.viewport).hasText('Photo by Ornella Binni')
    assert.strictEqual(works.element.offsetWidth, 384, 'w-96')
    assert.ok(works.maxScrollLeft > 0, 'the row is wider than the area')

    await works.hover()
    assert.true(works.isScrollbarVisible('horizontal'), 'shown while the pointer is over it')
    assert.strictEqual(
      works.scrollbar('vertical'),
      null,
      'no vertical scrollbar: nothing overflows down',
    )
    await works.scrollTo({ left: works.maxScrollLeft })
    assert.ok(works.thumbOffset('horizontal') > 0, 'the thumb follows')
    await a11yAudit()
  })
})
