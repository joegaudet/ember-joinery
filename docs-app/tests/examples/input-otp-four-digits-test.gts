import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputOTPHarness } from '@ember-joinery/test-support'
import InputOTPFourDigits from 'docs-app/examples/input-otp-four-digits'

module('Example | input-otp-four-digits', function (hooks) {
  setupRenderingTest(hooks)

  test('a four-digit PIN, digits only', async function (assert) {
    await render(<template><InputOTPFourDigits /></template>)
    const pin = new InputOTPHarness()
    assert.strictEqual(pin.maxLength, 4)
    assert.dom(pin.input).hasAttribute('pattern', '^\\d+$').hasAttribute('inputmode', 'numeric')

    await pin.typeIn('1a2')
    assert.strictEqual(pin.value, '12', 'a letter is refused')
    await pin.paste('3456')
    assert.strictEqual(pin.value, '1234', 'a paste is cut to four')
    assert.true(pin.isComplete)
    await a11yAudit()
  })
})
