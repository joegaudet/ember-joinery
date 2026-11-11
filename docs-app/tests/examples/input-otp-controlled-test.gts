import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputOTPHarness } from '@ember-joinery/test-support'
import InputOTPControlled from 'docs-app/examples/input-otp-controlled'

module('Example | input-otp-controlled', function (hooks) {
  setupRenderingTest(hooks)

  test('the code is the example’s, and the text below says what it is', async function (assert) {
    await render(<template><InputOTPControlled /></template>)
    const otp = new InputOTPHarness()
    assert.dom('.text-center').hasText('Enter your one-time password.')

    await otp.typeIn('123')
    assert.dom('.text-center').hasText('You entered: 123')
    await otp.paste('456')
    assert.dom('.text-center').hasText('You entered: 123456')
    assert.true(otp.isComplete)
    await otp.clear()
    assert.dom('.text-center').hasText('Enter your one-time password.')
    await a11yAudit()
  })
})
