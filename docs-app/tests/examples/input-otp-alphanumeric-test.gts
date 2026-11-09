import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputOTPHarness } from '@ember-joinery/test-support'
import InputOTPAlphanumeric from 'docs-app/examples/input-otp-alphanumeric'

module('Example | input-otp-alphanumeric', function (hooks) {
  setupRenderingTest(hooks)

  test('letters and digits, nothing else', async function (assert) {
    await render(<template><InputOTPAlphanumeric /></template>)
    const otp = new InputOTPHarness()
    await otp.typeIn('a1-B2')
    assert.strictEqual(otp.value, 'a1B2', 'the dash is refused')
    await otp.autofill('X9Y8Z7')
    assert.deepEqual(otp.chars, ['X', '9', 'Y', '8', 'Z', '7'], 'an autofilled code, at once')
    await a11yAudit()
  })
})
