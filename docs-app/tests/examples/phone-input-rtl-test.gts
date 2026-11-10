import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { PhoneInputHarness } from '@ember-joinery/maskito/test-support'
import PhoneInputRtl from 'docs-app/examples/phone-input-rtl'

module('Example | phone-input-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, in Arabic, the number still reads left to right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl"><PhoneInputRtl /></DirectionProvider>
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    assert.strictEqual(phone.label, 'رقم الجوال')
    assert.strictEqual(phone.picker.label, 'الدولة')
    assert.strictEqual(phone.countryName, 'المملكة العربية السعودية')
    await phone.typeText('501234567')
    assert.strictEqual(phone.value, '+966 50 123-4567')
    assert.strictEqual(getComputedStyle(phone.control).direction, 'ltr')
    await a11yAudit()
  })
})
