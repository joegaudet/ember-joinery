import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { FieldHarness, InputOTPHarness } from '@ember-joinery/test-support'
import InputOTPRtl from 'docs-app/examples/input-otp-rtl'

module('Example | input-otp-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, the code runs from the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><InputOTPRtl /></DirectionProvider>
      </template>,
    )
    const field = new FieldHarness()
    const otp = field.find(InputOTPHarness)
    assert.strictEqual(otp.label, 'رمز التحقق', 'the FieldLabel names it')
    assert.deepEqual(otp.chars, ['1', '2', '3', '4', '5', '6'], '@defaultValue')
    const [first, , , , , last] = otp.slots.map(slot => slot.getBoundingClientRect())
    assert.ok(first!.left > last!.left, 'the first slot is on the right')
    assert.strictEqual(
      Math.round(field.labelElement!.getBoundingClientRect().right),
      Math.round(field.element.getBoundingClientRect().right),
      'the label starts at the right',
    )
    assert.strictEqual(getComputedStyle(field.element).maxWidth, '320px', 'max-w-xs')
    await a11yAudit()
  })
})
