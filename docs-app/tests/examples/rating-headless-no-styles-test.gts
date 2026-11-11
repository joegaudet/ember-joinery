import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { RatingHarness } from '@ember-joinery/test-support'
import RatingHeadlessNoStyles from 'docs-app/examples/rating-headless-no-styles'

module('Example | rating-headless-no-styles', function (hooks) {
  setupRenderingTest(hooks)

  test('the block shows the rating, and rating.Stars draws a star component for each item', async function (assert) {
    await render(<template><RatingHeadlessNoStyles /></template>)
    const rating = new RatingHarness()

    assert.strictEqual(rating.label, 'Rate it')
    assert.dom(rating.element).containsText('0 of 5')
    assert.strictEqual(rating.starTexts, '★ ★ ★ ★ ★')
    assert.dom('.item > .icon', rating.element).exists({ count: 5 }, 'Star, once an item')
    assert.dom(rating.part('items')).hasClass('flex')

    await rating.select(4)
    assert.strictEqual(rating.value, 4)
    assert.strictEqual(rating.stars, '★ ★ ★ ★ ☆')
    assert.dom(rating.element).containsText('4 of 5')

    await rating.focus()
    assert.strictEqual(rating.focused, 4)
    await rating.press('ArrowLeft')
    assert.strictEqual(rating.value, 3)
    assert.dom(rating.element).containsText('3 of 5')
    await a11yAudit()
  })
})
