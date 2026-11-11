import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  CheckboxHarness,
  FieldSetHarness,
  InputHarness,
  SelectHarness,
} from '@ember-joinery/test-support'
import FieldDemo from 'docs-app/examples/field-demo'

module('Example | field-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a payment form: card, expiry month and year, billing address and comments', async function (assert) {
    await render(<template><FieldDemo /></template>)
    const [payment, billing] = new FieldSetHarness().element.parentElement!.querySelectorAll(
      ':scope > [data-test-jn="field-set"]',
    )
    assert.dom(payment).containsText('Payment Method')
    assert.dom(billing).containsText('Billing Address')

    const month = new SelectHarness({ index: 0 })
    const year = new SelectHarness({ index: 1 })
    assert.strictEqual(month.label, 'Month')
    assert.strictEqual(month.valueText, 'MM')
    assert.strictEqual(year.label, 'Year')
    assert.strictEqual(year.valueText, 'YYYY')
    const cvv = new InputHarness({ index: 2 })
    assert.strictEqual(
      month.trigger.offsetWidth,
      cvv.element.offsetWidth,
      'each select fills its grid column, as the CVV input does',
    )

    await month.open()
    assert.strictEqual(month.optionTexts.length, 12)
    await a11yAudit()
    await month.pressOption('07')
    assert.strictEqual(month.valueText, '07')
    await year.open()
    assert.deepEqual(year.optionTexts, ['2024', '2025', '2026', '2027', '2028', '2029'])
    await year.pressOption('2027')
    assert.strictEqual(year.valueText, '2027')

    const sameAsShipping = new CheckboxHarness()
    assert.true(sameAsShipping.isChecked)
    assert.strictEqual(sameAsShipping.label, 'Same as shipping address')
    await a11yAudit()
  })
})
