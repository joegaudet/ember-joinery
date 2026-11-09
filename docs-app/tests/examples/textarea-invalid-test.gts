import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, TextareaHarness } from '@ember-joinery/test-support'
import TextareaInvalid from 'docs-app/examples/textarea-invalid'

module('Example | textarea-invalid', function (hooks) {
  setupRenderingTest(hooks)

  test('an invalid textarea, its field in the destructive colour', async function (assert) {
    await render(<template><TextareaInvalid /></template>)
    const field = new FieldHarness()
    const message = field.find(TextareaHarness)

    assert.true(field.isInvalid)
    assert.true(message.isInvalid)
    assert.strictEqual(field.description, 'Please enter a valid message.')
    assert.strictEqual(
      getComputedStyle(field.labelElement!).color,
      getComputedStyle(field.element).color,
      'its label in the field colour',
    )
    await a11yAudit()
  })
})
