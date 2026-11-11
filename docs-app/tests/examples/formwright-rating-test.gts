import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { RatingFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightRating from 'docs-app/examples/formwright-rating'

class ReviewForm extends FormHarness {
  static override formName = 'review'
  @field(RatingFieldHarness) declare rating: RatingFieldHarness
  @field(RatingFieldHarness) declare value: RatingFieldHarness
}

module('Example | formwright-rating', function (hooks) {
  setupRenderingTest(hooks)

  test('a rating stores the stars picked, its hint and errors on each one', async function (assert) {
    await render(<template><FormwrightRating /></template>)
    const review = new ReviewForm()
    assert.strictEqual(review.rating.label, 'Rating')
    assert.strictEqual(review.rating.rating.label, 'Rating', 'which names the stars')
    assert.strictEqual(review.rating.value, null)
    const hint = review.rating.element.querySelector('[data-test-fw-hint]')!.id
    assert.dom(review.rating.rating.input(1)).hasAttribute('aria-describedby', hint)

    await review.submit()
    assert.deepEqual(review.rating.errors, ['Pick a rating.'])
    assert.dom(review.rating.rating.input(1)).hasAttribute('aria-invalid', 'true').isFocused()
    await a11yAudit()

    await review.rating.select(4)
    assert.strictEqual(review.rating.value, 4)
    assert.strictEqual(review.rating.stars, '★ ★ ★ ★ ☆')
    assert.deepEqual(review.rating.errors, [], 'the error clears once it is picked')

    assert.strictEqual(review.value.value, 3.5, 'half stars, with @step')
    assert.strictEqual(review.value.rating.labelOf(3.5), '3.5 stars')
    await review.value.focus()
    await review.value.press('ArrowRight')
    assert.strictEqual(review.value.value, 4)
    await a11yAudit()
  })
})
