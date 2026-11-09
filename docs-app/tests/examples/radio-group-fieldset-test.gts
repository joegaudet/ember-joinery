import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldSetHarness, RadioGroupHarness, tab } from '@ember-joinery/test-support'
import RadioGroupFieldset from 'docs-app/examples/radio-group-fieldset'

module('Example | radio-group-fieldset', function (hooks) {
  setupRenderingTest(hooks)

  test('a radio group under a field set legend', async function (assert) {
    await render(<template><RadioGroupFieldset /></template>)
    const set = new FieldSetHarness()
    const plan = new RadioGroupHarness()

    assert.strictEqual(set.legend, 'Subscription Plan')
    assert.strictEqual(set.description, 'Yearly and lifetime plans offer significant savings.')
    assert.strictEqual(plan.value, 'monthly')
    assert.strictEqual(plan.labelOf('lifetime'), 'Lifetime ($299.99)')
    assert.strictEqual(
      getComputedStyle(set.element).rowGap,
      '12px',
      'has-[>[data-slot=radio-group]]:gap-3',
    )
    await tab()
    await plan.press('ArrowDown')
    assert.strictEqual(plan.value, 'yearly')
    await a11yAudit()
  })
})
