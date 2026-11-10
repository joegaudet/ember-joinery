import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputGroupHarness, InputHarness } from '@ember-joinery/test-support'
import MaskedInputInputGroup from 'docs-app/examples/masked-input-input-group'

module('Example | masked-input-input-group', function (hooks) {
  setupRenderingTest(hooks)

  test("the maskito modifier masks an Input Group's own inputs", async function (assert) {
    await render(<template><MaskedInputInputGroup /></template>)
    const card = new InputHarness('card')
    const expiry = new InputHarness('expiry')

    assert.strictEqual(card.label, 'Card number')
    await card.fillIn('4242424242424242')
    assert.strictEqual(card.value, '4242 4242 4242 4242')
    const [group] = InputGroupHarness.findAll()
    assert.strictEqual(group!.control, card.control, 'it is the group’s control')

    await expiry.fillIn('0929')
    assert.strictEqual(expiry.value, '09/29', 'a month and a year, mm/yy')
    await a11yAudit()
  })
})
