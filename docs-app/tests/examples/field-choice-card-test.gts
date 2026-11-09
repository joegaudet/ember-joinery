import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  FieldHarness,
  FieldSetHarness,
  LabelHarness,
  RadioGroupHarness,
} from '@ember-joinery/test-support'
import FieldChoiceCard from 'docs-app/examples/field-choice-card'

module('Example | field-choice-card', function (hooks) {
  setupRenderingTest(hooks)

  test('two cards, each a field inside its label; a press on a card chooses it', async function (assert) {
    await render(<template><FieldChoiceCard /></template>)
    const set = new FieldSetHarness()
    const environment = new RadioGroupHarness()
    const [kubernetes, vm] = FieldHarness.findAll()
    const [kubernetesCard, vmCard] = LabelHarness.findAll()

    assert.strictEqual(set.legend, 'Compute Environment')
    assert.strictEqual(set.description, 'Select the compute environment for your cluster.')
    assert.deepEqual(environment.options, ['kubernetes', 'vm'])
    assert.strictEqual(environment.value, 'kubernetes')
    assert.strictEqual(kubernetes!.label, 'Kubernetes', "a card's title is its label")
    assert.strictEqual(kubernetes!.description, 'Run GPU workloads on a K8s cluster.')
    assert.strictEqual(vm!.title, 'Virtual Machine')
    assert.strictEqual(environment.labelOf('vm'), 'Virtual Machine')

    const chosen = getComputedStyle(kubernetesCard!.element).backgroundColor
    const other = getComputedStyle(vmCard!.element).backgroundColor
    assert.notStrictEqual(chosen, other, 'the chosen card is tinted')

    await vmCard!.click()
    assert.strictEqual(environment.value, 'vm')
    assert.strictEqual(getComputedStyle(vmCard!.element).backgroundColor, chosen)
    await a11yAudit()
  })
})
