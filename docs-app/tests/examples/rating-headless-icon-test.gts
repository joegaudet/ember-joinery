import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { RatingHarness } from '@ember-joinery/test-support'
import RatingHeadlessIcon from 'docs-app/examples/rating-headless-icon'

module('Example | rating-headless-icon', function (hooks) {
  setupRenderingTest(hooks)

  test('each item draws its value, and the picked ones turn over', async function (assert) {
    await render(<template><RatingHeadlessIcon /></template>)
    const rating = new RatingHarness()

    assert.strictEqual(rating.label, 'Rate it')
    assert.strictEqual(rating.value, 0)
    assert.strictEqual(rating.starTexts, '1 2 3 4 5', 'the icon component shows each value')
    assert.strictEqual(rating.labelOf(3), '3 stars', 'each radio keeps its name')

    await rating.select(3)
    assert.strictEqual(rating.value, 3)
    assert.strictEqual(rating.stars, '★ ★ ★ ☆ ☆')
    assert.dom('.rotate-180', rating.element).exists({ count: 3 }, 'told @isSelected')
    assert.dom('[aria-hidden="true"] > div', rating.item(4)).doesNotHaveClass('rotate-180')

    await rating.focus()
    await rating.press('ArrowRight')
    assert.strictEqual(rating.value, 4, 'the keyboard is a radio group’s')
    await rating.select(4)
    assert.strictEqual(rating.value, 0, 'picking it again clears it')
    assert.dom('.rotate-180', rating.element).doesNotExist()
    await a11yAudit()
  })
})
