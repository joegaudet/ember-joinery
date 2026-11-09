import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { RatingHarness, tab } from '@ember-joinery/test-support'
import RatingDemo from 'docs-app/examples/rating-demo'

module('Example | rating-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a half rating, three and a half stars to start; a click or the arrows rate', async function (assert) {
    await render(<template><RatingDemo /></template>)
    const recipe = new RatingHarness()

    assert.strictEqual(recipe.label, 'Rate this recipe')
    assert.strictEqual(recipe.total, 10, 'an item for each half star')
    assert.strictEqual(recipe.value, 3.5)
    assert.strictEqual(recipe.labelOf(4.5), '4.5 stars')
    assert.dom(recipe.element.parentElement!).containsText('3.5 out of 5')

    await recipe.select(2)
    assert.strictEqual(recipe.value, 2)
    assert.dom(recipe.element.parentElement!).containsText('2 out of 5')

    await recipe.focus()
    assert.strictEqual(recipe.focused, 2, 'focus on the picked half star')
    await recipe.press('ArrowRight')
    assert.strictEqual(recipe.value, 2.5, 'by half a star')
    await recipe.select(2.5)
    assert.strictEqual(recipe.value, 0, 'picking it again clears it')
    await a11yAudit()
  })

  test('Tab reaches the picked half star', async function (assert) {
    await render(<template><RatingDemo /></template>)
    const recipe = new RatingHarness()
    await tab()
    assert.strictEqual(recipe.focused, 3.5)
    await a11yAudit()
  })
})
