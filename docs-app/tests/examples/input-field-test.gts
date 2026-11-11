import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, InputHarness, LabelHarness } from '@ember-joinery/test-support'
import InputField from 'docs-app/examples/input-field'

module('Example | input-field', function (hooks) {
  setupRenderingTest(hooks)

  test('a username input in a field; a press on the label focuses it', async function (assert) {
    await render(<template><InputField /></template>)
    const field = new FieldHarness()
    const username = field.find(InputHarness)

    assert.strictEqual(username.label, 'Username')
    assert.strictEqual(field.description, 'Choose a unique username for your account.')
    await field.find(LabelHarness).click()
    assert.true(username.isFocused)
    await a11yAudit()
  })
})
