import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, TextareaHarness } from '@ember-joinery/test-support'
import FieldTextarea from 'docs-app/examples/field-textarea'

module('Example | field-textarea', function (hooks) {
  setupRenderingTest(hooks)

  test('a feedback textarea, four rows tall, with its help text', async function (assert) {
    await render(<template><FieldTextarea /></template>)
    const field = new FieldHarness()
    const feedback = field.find(TextareaHarness)

    assert.strictEqual(field.label, 'Feedback')
    assert.strictEqual(field.description, 'Share your thoughts about our service.')
    assert.strictEqual(feedback.label, 'Feedback')
    assert.strictEqual(feedback.placeholder, 'Your feedback helps us improve...')
    assert.strictEqual(feedback.control.rows, 4)
    await feedback.fillIn('Great service!')
    assert.strictEqual(feedback.value, 'Great service!')
    await a11yAudit()
  })
})
