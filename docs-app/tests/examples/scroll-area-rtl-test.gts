import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ScrollAreaHarness, SeparatorHarness } from '@ember-joinery/test-support'
import ScrollAreaRtl from 'docs-app/examples/scroll-area-rtl'

module('Example | scroll-area-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, the scrollbar is on the left and the tags start at the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><ScrollAreaRtl /></DirectionProvider>
      </template>,
    )
    const tags = new ScrollAreaHarness()
    assert.dom('h4', tags.viewport).hasText('العلامات')
    assert.strictEqual(tags.findAll(SeparatorHarness).length, 50, 'one under each tag')

    const heading = tags.viewport.querySelector('h4')!
    const words = document.createRange()
    words.selectNodeContents(heading)
    const text = words.getBoundingClientRect()
    const box = heading.getBoundingClientRect()
    assert.true(box.right - text.right < text.left - box.left, 'its title starts at the right')

    await tags.hover()
    assert.true(tags.isScrollbarVisible())
    const bar = tags.scrollbar()!
    const area = tags.element.getBoundingClientRect()
    assert.true(
      bar.getBoundingClientRect().left - area.left < area.right - bar.getBoundingClientRect().right,
      'the scrollbar is on the left',
    )
    await tags.scrollTo({ top: tags.maxScrollTop })
    assert.ok(tags.thumbOffset() > 0, 'the thumb follows')
    await a11yAudit()
  })
})
