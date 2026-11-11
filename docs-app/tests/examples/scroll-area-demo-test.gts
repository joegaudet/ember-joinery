import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ScrollAreaHarness, SeparatorHarness } from '@ember-joinery/test-support'
import ScrollAreaDemo from 'docs-app/examples/scroll-area-demo'

module('Example | scroll-area-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('fifty tags, each over a separator, in a 288px area that scrolls', async function (assert) {
    await render(<template><ScrollAreaDemo /></template>)
    const tags = new ScrollAreaHarness()
    assert.strictEqual(tags.element.offsetHeight, 288, 'h-72')
    assert.strictEqual(tags.element.offsetWidth, 192, 'w-48')
    assert.dom('h4', tags.viewport).hasText('Tags')
    assert.dom(tags.viewport).containsText('v1.2.0-beta.50')
    assert.dom(tags.viewport).containsText('v1.2.0-beta.1')

    const separators = tags.findAll(SeparatorHarness)
    assert.strictEqual(separators.length, 50, 'one under each tag')
    const [first] = separators
    assert.true(first!.isDecorative, 'they only draw a line, as upstream’s')
    assert.strictEqual(first!.orientation, 'horizontal')
    const style = getComputedStyle(first!.element)
    assert.strictEqual(style.marginTop, '8px', 'my-2')
    assert.strictEqual(style.height, '1px')

    assert.strictEqual(tags.scrollbar(), null, 'no scrollbar until the pointer is over it')
    await tags.hover()
    assert.true(tags.isScrollbarVisible())
    assert.ok(tags.maxScrollTop > 0, 'the list is taller than the area')
    await tags.scrollTo({ top: tags.maxScrollTop })
    assert.ok(tags.thumbOffset() > 0, 'the thumb follows')
    await a11yAudit()
  })
})
