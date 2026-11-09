import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldSetHarness, LabelHarness, RadioGroupHarness, tab } from '@ember-joinery/test-support'
import FieldRadio from 'docs-app/examples/field-radio'

module('Example | field-radio', function (hooks) {
  setupRenderingTest(hooks)

  test('three plans, monthly chosen; a label or the arrow keys choose another', async function (assert) {
    await render(<template><FieldRadio /></template>)
    const set = new FieldSetHarness()
    const plan = new RadioGroupHarness()

    assert.strictEqual(set.legend, 'Subscription Plan')
    assert.strictEqual(set.legendVariant, 'label')
    assert.strictEqual(set.description, 'Yearly and lifetime plans offer significant savings.')
    assert.deepEqual(plan.options, ['monthly', 'yearly', 'lifetime'], 'each item, in its field')
    assert.strictEqual(plan.value, 'monthly')
    assert.strictEqual(plan.labelOf('yearly'), 'Yearly ($99.99/year)')

    await tab()
    assert.strictEqual(plan.focused, 'monthly')
    await plan.press('ArrowDown')
    assert.strictEqual(plan.value, 'yearly')

    await set.findAll(LabelHarness).at(-1)!.click()
    assert.strictEqual(plan.value, 'lifetime')
    await a11yAudit()
  })
})
