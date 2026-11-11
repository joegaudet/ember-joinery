import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { IconHarness, RatingHarness } from '@ember-joinery/test-support'
import RatingIcon from 'docs-app/examples/rating-icon'

module('Example | rating-icon', function (hooks) {
  setupRenderingTest(hooks)

  test('three hearts, two of them filled, each named a heart', async function (assert) {
    await render(<template><RatingIcon /></template>)
    const rating = new RatingHarness()

    assert.strictEqual(rating.label, 'How much do you like it?')
    assert.strictEqual(rating.total, 3)
    assert.strictEqual(rating.stars, '★ ★ ☆')
    assert.deepEqual(
      rating.options.map(value => rating.labelOf(value)),
      ['1 heart', '2 hearts', '3 hearts'],
    )
    assert.strictEqual(rating.findAll(IconHarness).length, 3)
    await rating.select(3)
    assert.strictEqual(rating.stars, '★ ★ ★')
    await a11yAudit()
  })
})
