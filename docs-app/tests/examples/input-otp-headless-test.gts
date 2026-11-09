import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputOTPHarness } from '@ember-joinery/test-support'
import InputOTPHeadless from 'docs-app/examples/input-otp-headless'

module('Example | input-otp-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('slots of its own, drawn from the state it yields', async function (assert) {
    await render(<template><InputOTPHeadless /></template>)
    const code = new InputOTPHarness()
    assert.strictEqual(code.label, 'Code sent to your phone')
    assert.strictEqual(code.slots.length, 4)
    assert.strictEqual(getComputedStyle(code.element).display, 'flex', 'its @containerClass')

    await code.focus()
    assert.strictEqual(code.activeIndex, 0)
    assert.true(code.hasCaret(0), 'its own caret, where the next digit goes')
    await code.typeIn('42')
    assert.deepEqual(code.chars, ['4', '2', '', ''])
    assert.true(code.hasCaret(2))
    await a11yAudit()
  })
})
