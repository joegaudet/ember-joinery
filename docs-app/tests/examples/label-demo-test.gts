import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness, LabelHarness } from '@ember-joinery/test-support'
import LabelDemo from 'docs-app/examples/label-demo'

module('Example | label-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a label names its checkbox, and a click on it toggles the checkbox', async function (assert) {
    await render(<template><LabelDemo /></template>)
    const label = new LabelHarness()
    const terms = new CheckboxHarness()

    assert.strictEqual(label.text, 'Accept terms and conditions')
    assert.strictEqual(label.control, terms.element, 'it labels the checkbox')
    assert.strictEqual(terms.label, 'Accept terms and conditions')
    assert.false(terms.isChecked)

    await label.click()
    assert.true(terms.isChecked, 'a click on the label checks it')
    await label.click()
    assert.false(terms.isChecked, 'and another unchecks it')
    await a11yAudit()
  })
})
