import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputOTPHarness, tab } from '@ember-joinery/test-support'
import InputOTPDisabled from 'docs-app/examples/input-otp-disabled'

module('Example | input-otp-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('a disabled code, dimmed and out of the tab order', async function (assert) {
    await render(<template><InputOTPDisabled /></template>)
    const otp = new InputOTPHarness()
    assert.true(otp.isDisabled)
    assert.dom(otp.input).hasAttribute('id', 'disabled')
    assert.deepEqual(otp.chars, ['1', '2', '3', '4', '5', '6'])
    assert.strictEqual(getComputedStyle(otp.element).opacity, '0.5', 'has-disabled:opacity-50')
    await tab()
    assert.false(otp.isFocused)
    await a11yAudit()
  })
})
