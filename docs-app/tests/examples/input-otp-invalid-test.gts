import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputOTPHarness } from '@ember-joinery/test-support'
import InputOTPInvalid from 'docs-app/examples/input-otp-invalid'

module('Example | input-otp-invalid', function (hooks) {
  setupRenderingTest(hooks)

  test('every slot marked invalid, in three groups of two', async function (assert) {
    await render(<template><InputOTPInvalid /></template>)
    const otp = new InputOTPHarness()
    assert.true(otp.isInvalid)
    assert.deepEqual(otp.chars, ['0', '0', '0', '0', '0', '0'])
    assert.strictEqual(otp.groups.length, 3)
    for (const slot of otp.slots) assert.dom(slot).hasAttribute('aria-invalid', 'true')
    const group = getComputedStyle(otp.groups[0]!)
    assert.ok(group.boxShadow.includes(' 3px'), 'has-aria-invalid:ring-3: the group rings')

    await otp.focus()
    await otp.press('Backspace')
    assert.strictEqual(otp.value, '00000', 'its code is the example’s, and still editable')
    await a11yAudit()
  })
})
