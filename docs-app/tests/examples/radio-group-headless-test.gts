import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { RadioGroupHarness } from '@ember-joinery/test-support'
import RadioGroupHeadless from 'docs-app/examples/radio-group-headless'

module('Example | radio-group-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a radio group with styles of its own, named by its label', async function (assert) {
    await render(<template><RadioGroupHeadless /></template>)
    const drink = new RadioGroupHarness()

    assert.strictEqual(drink.label, 'Drink')
    assert.deepEqual(drink.options, ['coffee', 'tea', 'water'])
    assert.strictEqual(drink.value, 'tea')
    assert.dom(drink.item('tea').querySelector('[data-test-jn-part="indicator"]')).exists()

    await drink.focus('tea')
    await drink.press('ArrowDown')
    assert.strictEqual(drink.value, 'water')
    assert.dom(drink.item('tea').querySelector('[data-test-jn-part="indicator"]')).doesNotExist()
    await drink.choose('coffee')
    assert.strictEqual(drink.value, 'coffee')
    await a11yAudit()
  })
})
