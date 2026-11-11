import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness, FieldHarness, LabelHarness } from '@ember-joinery/test-support'
import CheckboxBasic from 'docs-app/examples/checkbox-basic'

module('Example | checkbox-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('a checkbox beside its field label', async function (assert) {
    await render(<template><CheckboxBasic /></template>)
    const field = new FieldHarness()
    const terms = field.find(CheckboxHarness)

    assert.strictEqual(field.orientation, 'horizontal')
    assert.strictEqual(terms.label, 'Accept terms and conditions')
    await field.find(LabelHarness).click()
    assert.true(terms.isChecked)
    await terms.uncheck()
    assert.false(terms.isChecked)
    await a11yAudit()
  })
})
