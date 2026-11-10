import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness, InputHarness, SelectHarness } from '@ember-joinery/test-support'
import FieldRtl from 'docs-app/examples/field-rtl'

module('Example | field-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('the payment form in Arabic, right to left, with its month and year selects', async function (assert) {
    await render(<template><FieldRtl /></template>)
    const month = new SelectHarness({ index: 0 })
    const year = new SelectHarness({ index: 1 })
    assert.strictEqual(month.label, 'الشهر')
    assert.strictEqual(year.label, 'السنة')
    assert.strictEqual(month.valueText, '', 'nothing chosen, and no placeholder, as upstream')

    const name = new InputHarness({ index: 0 })
    const right = (element: Element) => element.getBoundingClientRect().right
    assert.true(
      Math.abs(right(month.trigger) - right(name.element)) <= 1,
      'the month comes first, at the right',
    )

    await month.open()
    assert.dom(month.content).hasAttribute('dir', 'rtl')
    assert.strictEqual(month.optionTexts[0], 'ش.ش')
    assert.strictEqual(month.optionTexts[7], '٠٧')
    await a11yAudit()
    await month.pressOption('07')
    assert.strictEqual(month.valueText, '٠٧')
    await year.open()
    await year.pressOption('2028')
    assert.strictEqual(year.valueText, '2028')

    const sameAsShipping = new CheckboxHarness()
    assert.true(sameAsShipping.isChecked)
    assert.strictEqual(sameAsShipping.label, 'نفس عنوان الشحن')
    await a11yAudit()
  })
})
