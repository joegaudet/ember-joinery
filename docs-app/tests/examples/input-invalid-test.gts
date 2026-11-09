import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, InputHarness } from '@ember-joinery/test-support'
import InputInvalid from 'docs-app/examples/input-invalid'

module('Example | input-invalid', function (hooks) {
  setupRenderingTest(hooks)

  test('an invalid input, its field in the destructive colour', async function (assert) {
    await render(<template><InputInvalid /></template>)
    const field = new FieldHarness()
    const input = field.find(InputHarness)

    assert.true(field.isInvalid)
    assert.true(input.isInvalid)
    assert.strictEqual(input.label, 'Invalid Input')
    assert.strictEqual(field.description, 'This field contains validation errors.')
    assert.strictEqual(
      getComputedStyle(input.element).borderTopColor,
      getComputedStyle(field.element).color,
      'aria-invalid:border-destructive, as the field',
    )
    await a11yAudit()
  })
})
