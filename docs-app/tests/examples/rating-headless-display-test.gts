import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { RatingHarness } from '@ember-joinery/test-support'
import RatingHeadlessDisplay from 'docs-app/examples/rating-headless-display'

module('Example | rating-headless-display', function (hooks) {
  setupRenderingTest(hooks)

  test('three ratings to show: summarised, in a label block, and in a block of their own', async function (assert) {
    await render(<template><RatingHeadlessDisplay /></template>)
    const [summarised, labelled, laidOut] = RatingHarness.findAll()

    assert.strictEqual(summarised!.summary, 'Rated 2 out of 5')
    assert.strictEqual(summarised!.stars, '★ ★ ☆ ☆ ☆')
    assert.true(summarised!.isReadonly)

    assert.dom(labelled!.part('label')).hasText('4 of 5')
    assert.strictEqual(labelled!.summary, '', 'the label block shows the rating instead')
    assert.strictEqual(labelled!.stars, '★ ★ ★ ★ ☆')

    assert.strictEqual(laidOut!.value, 3)
    assert.strictEqual(laidOut!.stars, '★ ★ ★ ☆ ☆', 'rating.Stars draws every item')
    assert.strictEqual(laidOut!.starTexts, '★ ★ ★ ★ ★', 'with the default icon')
    assert.dom(laidOut!.element).containsText('3 of 5')
    assert.true(laidOut!.isReadonly)

    await laidOut!.select(5)
    assert.strictEqual(laidOut!.value, 3, 'display only: a click changes nothing')
    await a11yAudit()
  })
})
