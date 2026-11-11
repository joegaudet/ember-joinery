import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  CardHarness,
  FieldHarness,
  InputOTPHarness,
} from '@ember-joinery/test-support'
import InputOTPForm from 'docs-app/examples/input-otp-form'

module('Example | input-otp-form', function (hooks) {
  setupRenderingTest(hooks)

  test('a card to verify a login with a required six-digit code', async function (assert) {
    await render(<template><InputOTPForm /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Verify your login')
    assert.strictEqual(
      card.description,
      'Enter the verification code we sent to your email address: m@example.com.',
    )

    const [code, footer] = FieldHarness.findAll()
    const otp = code!.find(InputOTPHarness)
    assert.strictEqual(otp.label, 'Verification code', 'the FieldLabel names it')
    assert.true(otp.isRequired)
    assert.strictEqual(otp.groups.length, 2)
    assert.strictEqual(otp.separators.length, 1)
    const separator = otp.separators[0]!
    assert.strictEqual(getComputedStyle(separator).display, 'block', 'a block, as upstream’s shows')
    assert.strictEqual(
      getComputedStyle(separator.querySelector('svg')!).width,
      '24px',
      'with lucide’s default size',
    )
    const slot = getComputedStyle(otp.slots[0]!)
    assert.strictEqual(slot.height, '48px', 'h-12 on each slot')
    assert.strictEqual(slot.width, '44px', 'w-11')
    assert.strictEqual(slot.fontSize, '20px', 'text-xl')
    assert.strictEqual(code!.description, 'I no longer have access to this email address.')

    const [resend, verify] = ButtonHarness.findAll()
    assert.strictEqual(resend!.label, 'Resend Code')
    assert.strictEqual(resend!.variant, 'outline')
    assert.strictEqual(resend!.size, 'xs')
    const centre = (rect: DOMRect) => rect.top + rect.height / 2
    const button = resend!.element.getBoundingClientRect()
    const label = code!.labelElement!.getBoundingClientRect()
    assert.ok(Math.abs(centre(button) - centre(label)) <= 1, 'beside the label, centred on it')
    assert.ok(button.left > label.right, 'justify-between: at the far end')
    assert.strictEqual(verify!.label, 'Verify')
    assert.dom(verify!.element).hasAttribute('type', 'submit')
    assert.strictEqual(
      verify!.element.offsetWidth,
      footer!.element.clientWidth,
      'w-full: as wide as its field',
    )
    assert.strictEqual(footer!.text, 'Verify Having trouble signing in? Contact support')

    await otp.typeIn('424242')
    assert.true(otp.isComplete)
    assert.strictEqual(otp.value, '424242')
    await a11yAudit()
  })
})
