import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness } from '@ember-joinery/test-support'
import { MaskedInputHarness } from '@ember-joinery/maskito/test-support'
import MaskedInputDemo from 'docs-app/examples/masked-input-demo'

module('Example | masked-input-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('the phone and postal code masks shape what is typed', async function (assert) {
    await render(<template><MaskedInputDemo /></template>)
    const phone = new MaskedInputHarness('phone')
    const postalCode = new MaskedInputHarness('postal-code')

    assert.strictEqual(phone.label, 'Phone')
    await phone.fillIn('5551234567')
    assert.strictEqual(phone.value, '(555) 123-4567', 'filled in at once, as autofill does')

    await postalCode.typeText('k1a0b1x')
    assert.strictEqual(
      postalCode.value,
      'k1a 0b1',
      'typed: the space goes in, the extra x does not',
    )
    const [, field] = FieldHarness.findAll()
    assert.strictEqual(
      field!.description,
      'A letter, a digit, a letter, then a space and the same again.',
    )
    await a11yAudit()
  })
})
