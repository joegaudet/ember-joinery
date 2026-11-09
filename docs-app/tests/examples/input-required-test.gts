import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, InputHarness } from '@ember-joinery/test-support'
import InputRequired from 'docs-app/examples/input-required'

module('Example | input-required', function (hooks) {
  setupRenderingTest(hooks)

  test('a required input, its label marked with a red star', async function (assert) {
    await render(<template><InputRequired /></template>)
    const field = new FieldHarness()
    const input = field.find(InputHarness)

    assert.true(input.isRequired)
    assert.strictEqual(field.label, 'Required Field *')
    assert.strictEqual(field.description, 'This field must be filled out.')
    const star = field.labelElement!.querySelector('span')!
    assert.notStrictEqual(
      getComputedStyle(star).color,
      getComputedStyle(field.labelElement!).color,
      'the star stands out, text-destructive',
    )
    assert.false(input.control.checkValidity(), 'empty, it is invalid')
    await input.fillIn('Something')
    assert.true(input.control.checkValidity())
    await a11yAudit()
  })
})
