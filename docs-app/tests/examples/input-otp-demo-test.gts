import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputOTPHarness } from '@ember-joinery/test-support'
import InputOTPDemo from 'docs-app/examples/input-otp-demo'

module('Example | input-otp-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('six slots in one group, starting from a code', async function (assert) {
    await render(<template><InputOTPDemo /></template>)
    const otp = new InputOTPHarness()
    assert.strictEqual(otp.maxLength, 6)
    assert.strictEqual(otp.groups.length, 1)
    assert.deepEqual(otp.chars, ['1', '2', '3', '4', '5', '6'], '@defaultValue')
    assert.true(otp.isComplete)

    await otp.focus()
    assert.deepEqual(otp.activeIndexes, [5], 'focus selects the last character')
    await otp.press('Backspace')
    await otp.typeIn('9')
    assert.strictEqual(otp.value, '123459')
    assert.strictEqual(otp.label, 'One-time password', 'named, though upstream leaves it unnamed')
    await a11yAudit()
  })
})
