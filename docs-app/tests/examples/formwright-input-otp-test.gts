import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { InputOTPFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightInputOtp from 'docs-app/examples/formwright-input-otp'

class VerifyForm extends FormHarness {
  static override formName = 'verify'
  @field(InputOTPFieldHarness) declare code: InputOTPFieldHarness
}

module('Example | formwright-input-otp', function (hooks) {
  setupRenderingTest(hooks)

  test('the code takes six digits, in two groups', async function (assert) {
    await render(<template><FormwrightInputOtp /></template>)
    const verify = new VerifyForm()
    assert.strictEqual(verify.code.otp.groups.length, 2)
    assert.strictEqual(verify.code.otp.label, 'Verification code')

    await verify.code.typeIn('12ab3')
    assert.strictEqual(verify.code.value, '123', 'it takes digits only')
    await verify.submit()
    assert.deepEqual(verify.code.errors, ['Enter all six digits.'])
    await a11yAudit()

    await verify.code.fillIn('123456')
    assert.true(verify.code.isComplete)
    assert.false(verify.code.isInvalid)
    await a11yAudit()
  })
})
