import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { PhoneInputHarness } from '@ember-joinery/maskito/test-support'
import PhoneInputNational from 'docs-app/examples/phone-input-national'

module('Example | phone-input-national', function (hooks) {
  setupRenderingTest(hooks)

  test('the national format, with the calling code beside the flag', async function (assert) {
    await render(<template><PhoneInputNational /></template>)
    const phone = new PhoneInputHarness('phone')
    assert.strictEqual(phone.value, '(212) 555-0123')
    assert.strictEqual(phone.callingCode, '+1')
    assert.strictEqual(phone.label, 'Phone')

    await phone.selectCountry('GB')
    await phone.clear()
    await phone.typeText('07400123456')
    assert.strictEqual(phone.value, '07400 123456', "the UK's national format, with its 0")
    assert.strictEqual(phone.callingCode, '+44')
    await a11yAudit()
  })
})
