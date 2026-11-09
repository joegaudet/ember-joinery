import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { RatingHarness } from '@ember-joinery/test-support'
import RatingDisplay from 'docs-app/examples/rating-display'

module('Example | rating-display', function (hooks) {
  setupRenderingTest(hooks)

  test('ratings to show, which say what they are and keep their value', async function (assert) {
    await render(<template><RatingDisplay /></template>)
    const [summarised, labelled, readonly] = RatingHarness.findAll()

    assert.strictEqual(summarised!.summary, 'Rated 4 out of 5')
    assert.strictEqual(summarised!.stars, '★ ★ ★ ★ ☆')
    assert.true(summarised!.isReadonly)
    assert.dom(summarised!.element).hasAttribute('data-size', 'sm')

    assert.dom(labelled!.part('label')).hasText('3 of 5')
    assert.strictEqual(labelled!.summary, '')

    assert.strictEqual(readonly!.label, 'Your rating')
    await readonly!.select(5)
    assert.strictEqual(readonly!.value, 2, 'a readonly rating keeps its value')
    await a11yAudit()
  })
})
