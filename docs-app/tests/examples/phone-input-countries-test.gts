import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { PhoneInputHarness } from '@ember-joinery/maskito/test-support'
import PhoneInputCountries from 'docs-app/examples/phone-input-countries'

module('Example | phone-input-countries', function (hooks) {
  setupRenderingTest(hooks)

  test('the picker offers the countries given, in their order', async function (assert) {
    await render(<template><PhoneInputCountries /></template>)
    const phone = new PhoneInputHarness('phone')
    assert.strictEqual(phone.country, 'SE')
    assert.deepEqual(await phone.countries(), ['DK', 'FI', 'IS', 'NO', 'SE'])
    await phone.picker.pressOption('NO')
    await phone.typeText('41234567')
    assert.strictEqual(phone.value, '+47 41 23-45-67')
    await a11yAudit()
  })
})
