import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { MaskedInputHarness } from '@ember-joinery/maskito/test-support'
import MaskedInputRtl from 'docs-app/examples/masked-input-rtl'

module('Example | masked-input-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, a date and an amount in riyals', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl"><MaskedInputRtl /></DirectionProvider>
      </template>,
    )
    const date = new MaskedInputHarness('date')
    const amount = new MaskedInputHarness('amount')
    assert.strictEqual(date.label, 'تاريخ الميلاد')
    assert.strictEqual(getComputedStyle(date.control).direction, 'rtl')

    await date.typeText('15031990')
    assert.strictEqual(date.value, '15/03/1990')
    await amount.typeText('2500')
    assert.strictEqual(amount.value, '2,500 ر.س', 'the riyal sign follows the number')
    await a11yAudit()
  })
})
