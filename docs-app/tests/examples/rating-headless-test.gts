import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { RatingHarness } from '@ember-joinery/test-support'
import RatingHeadless from 'docs-app/examples/rating-headless'

module('Example | rating-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a range input rates in quarters', async function (assert) {
    await render(<template><RatingHeadless /></template>)
    const film = new RatingHarness()

    assert.strictEqual(film.label, 'Rate the film')
    assert.strictEqual(film.value, 2.75)
    assert.dom(film.element).containsText('2.75 / 5')
    await film.select(4.25)
    assert.strictEqual(film.value, 4.25)
    assert.dom(film.element).containsText('4.25 / 5')
    assert.dom(film.part('range')).hasAttribute('step', '0.25')
    await a11yAudit()
  })
})
