import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness, FieldHarness } from '@ember-joinery/test-support'
import CheckboxInvalid from 'docs-app/examples/checkbox-invalid'

module('Example | checkbox-invalid', function (hooks) {
  setupRenderingTest(hooks)

  test('an invalid field turns its label and checkbox the destructive colour', async function (assert) {
    await render(<template><CheckboxInvalid /></template>)
    const field = new FieldHarness()
    const terms = field.find(CheckboxHarness)

    assert.true(field.isInvalid)
    assert.true(terms.isInvalid)
    assert.strictEqual(terms.label, 'Accept terms and conditions')
    const red = getComputedStyle(field.element).color
    assert.strictEqual(getComputedStyle(field.labelElement!).color, red, 'its label')
    assert.strictEqual(getComputedStyle(terms.element).borderTopColor, red, 'its border')
    await terms.check()
    assert.true(terms.isChecked)
    await a11yAudit()
  })
})
