import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness, FieldHarness } from '@ember-joinery/test-support'
import CheckboxDescription from 'docs-app/examples/checkbox-description'

module('Example | checkbox-description', function (hooks) {
  setupRenderingTest(hooks)

  test('a checked checkbox with a label and a description beside it', async function (assert) {
    await render(<template><CheckboxDescription /></template>)
    const field = new FieldHarness()
    const terms = field.find(CheckboxHarness)

    assert.true(terms.isChecked)
    assert.strictEqual(field.label, 'Accept terms and conditions')
    assert.strictEqual(
      field.description,
      'By clicking this checkbox, you agree to the terms and conditions.',
    )
    assert.strictEqual(getComputedStyle(field.element).alignItems, 'flex-start')
    await terms.toggle()
    assert.false(terms.isChecked)
    await a11yAudit()
  })
})
