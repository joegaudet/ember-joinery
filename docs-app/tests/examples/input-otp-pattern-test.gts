import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, InputOTPHarness, LabelHarness } from '@ember-joinery/test-support'
import InputOTPPattern from 'docs-app/examples/input-otp-pattern'

module('Example | input-otp-pattern', function (hooks) {
  setupRenderingTest(hooks)

  test('a labelled six-digit code that takes digits only', async function (assert) {
    await render(<template><InputOTPPattern /></template>)
    const field = new FieldHarness()
    const otp = field.find(InputOTPHarness)
    assert.strictEqual(otp.label, 'Digits Only', 'the FieldLabel names it')
    assert.strictEqual(field.control, otp.input)
    assert.strictEqual(otp.maxLength, 6)
    assert.dom(otp.input).hasAttribute('pattern', '^\\d+$').hasAttribute('inputmode', 'numeric')
    assert.ok(
      field.element.offsetWidth < field.element.parentElement!.clientWidth,
      'w-fit: not the full width a Field takes by default',
    )

    await field.find(LabelHarness).click()
    assert.true(otp.isFocused, 'a press on the label focuses it')
    await otp.typeIn('12ab34')
    assert.strictEqual(otp.value, '1234', 'letters are refused')
    await a11yAudit()
  })
})
