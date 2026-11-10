import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, SelectHarness } from '@ember-joinery/test-support'
import FieldSelect from 'docs-app/examples/field-select'

module('Example | field-select', function (hooks) {
  setupRenderingTest(hooks)

  test('a department is chosen, in a field as wide as the select', async function (assert) {
    await render(<template><FieldSelect /></template>)
    const field = new FieldHarness()
    assert.strictEqual(field.label, 'Department')
    assert.strictEqual(field.description, 'Select your department or area of work.')

    const select = new SelectHarness()
    assert.strictEqual(select.label, 'Department')
    assert.strictEqual(select.valueText, 'Choose department')
    assert.strictEqual(
      select.trigger.offsetWidth,
      field.element.offsetWidth,
      'the field stretches the trigger',
    )
    await select.open()
    assert.strictEqual(select.optionTexts.length, 8)
    await a11yAudit()
    await select.pressOption('support')
    assert.strictEqual(select.valueText, 'Customer Support')
    await a11yAudit()
  })
})
