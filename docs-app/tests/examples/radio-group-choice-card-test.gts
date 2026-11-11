import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, LabelHarness, RadioGroupHarness } from '@ember-joinery/test-support'
import RadioGroupChoiceCard from 'docs-app/examples/radio-group-choice-card'

module('Example | radio-group-choice-card', function (hooks) {
  setupRenderingTest(hooks)

  test('three plan cards; a press on a card chooses its plan', async function (assert) {
    await render(<template><RadioGroupChoiceCard /></template>)
    const plan = new RadioGroupHarness()
    const cards = LabelHarness.findAll()

    assert.deepEqual(plan.options, ['plus', 'pro', 'enterprise'])
    assert.strictEqual(plan.value, 'plus')
    assert.deepEqual(
      FieldHarness.findAll().map(field => field.label),
      ['Plus', 'Pro', 'Enterprise'],
    )
    assert.strictEqual(plan.labelOf('pro'), 'Pro')
    const chosen = getComputedStyle(cards[0]!.element).backgroundColor
    assert.notStrictEqual(getComputedStyle(cards[1]!.element).backgroundColor, chosen)
    await cards[2]!.click()
    assert.strictEqual(plan.value, 'enterprise')
    await a11yAudit()
  })
})
