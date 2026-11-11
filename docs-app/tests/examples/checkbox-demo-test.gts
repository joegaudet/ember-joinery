import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness, FieldHarness, LabelHarness } from '@ember-joinery/test-support'
import CheckboxDemo from 'docs-app/examples/checkbox-demo'

module('Example | checkbox-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('four checkboxes in fields: plain, described, disabled, and a card', async function (assert) {
    await render(<template><CheckboxDemo /></template>)
    const [terms, described, disabled, card] = FieldHarness.findAll()

    assert.strictEqual(terms!.find(CheckboxHarness).label, 'Accept terms and conditions')
    assert.false(terms!.find(CheckboxHarness).isChecked)
    await terms!.find(LabelHarness).click()
    assert.true(terms!.find(CheckboxHarness).isChecked, 'a press on the label checks it')

    assert.true(described!.find(CheckboxHarness).isChecked)
    assert.strictEqual(described!.description, 'By clicking this checkbox, you agree to the terms.')

    assert.true(disabled!.isDisabled)
    assert.true(disabled!.find(CheckboxHarness).isDisabled)
    assert.strictEqual(getComputedStyle(disabled!.labelElement!).opacity, '0.5', 'its label dims')

    const notifications = card!.find(CheckboxHarness)
    assert.strictEqual(card!.label, 'Enable notifications')
    assert.strictEqual(notifications.label, 'Enable notifications')
    assert.false(notifications.isChecked)
    await click(card!.part('description'))
    assert.true(notifications.isChecked, 'a press anywhere on the card checks it')
    await a11yAudit()
  })
})
