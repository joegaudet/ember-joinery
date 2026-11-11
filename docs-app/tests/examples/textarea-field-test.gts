import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, TextareaHarness } from '@ember-joinery/test-support'
import TextareaField from 'docs-app/examples/textarea-field'

module('Example | textarea-field', function (hooks) {
  setupRenderingTest(hooks)

  test('a labelled textarea with its description above it', async function (assert) {
    await render(<template><TextareaField /></template>)
    const field = new FieldHarness()
    const message = field.find(TextareaHarness)

    assert.strictEqual(message.label, 'Message')
    assert.strictEqual(field.description, 'Enter your message below.')
    assert.strictEqual(message.placeholder, 'Type your message here.')
    await message.fillIn('Hello')
    assert.strictEqual(message.value, 'Hello')
    await a11yAudit()
  })
})
