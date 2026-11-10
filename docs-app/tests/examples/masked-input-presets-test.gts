import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MaskedInputHarness } from '@ember-joinery/maskito/test-support'
import MaskedInputPresets from 'docs-app/examples/masked-input-presets'

module('Example | masked-input-presets', function (hooks) {
  setupRenderingTest(hooks)

  test('a price, a date and a time, each read back as a value', async function (assert) {
    await render(<template><MaskedInputPresets /></template>)
    const price = new MaskedInputHarness('price')
    const birthday = new MaskedInputHarness('birthday')
    const start = new MaskedInputHarness('start')

    await price.typeText('1234.567')
    assert.strictEqual(price.value, '$1,234.56', 'a prefix, thousands, and two decimals at most')
    assert.strictEqual(price.description, 'Reads as 1234.56')

    await birthday.typeText('07041990')
    assert.strictEqual(birthday.value, '07/04/1990')
    assert.strictEqual(birthday.description, 'Reads as Wed Jul 04 1990')

    await start.typeText('0930p')
    assert.strictEqual(start.value.replace(/\u00a0/g, ' '), '09:30 PM', 'a 12-hour clock')
    assert.strictEqual(start.description, 'Reads as 1290 minutes after midnight')
    await a11yAudit()
  })
})
