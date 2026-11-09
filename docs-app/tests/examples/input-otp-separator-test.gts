import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputOTPHarness } from '@ember-joinery/test-support'
import InputOTPSeparator from 'docs-app/examples/input-otp-separator'

module('Example | input-otp-separator', function (hooks) {
  setupRenderingTest(hooks)

  test('three groups of two, with a separator between each', async function (assert) {
    await render(<template><InputOTPSeparator /></template>)
    const otp = new InputOTPHarness()
    assert.strictEqual(otp.groups.length, 3)
    assert.strictEqual(otp.separators.length, 2)
    assert.dom(otp.separators[0]).hasAttribute('role', 'separator')
    const [first, second] = otp.groups.map(group => group.getBoundingClientRect())
    const separator = otp.separators[0]!.getBoundingClientRect()
    assert.ok(first!.right <= separator.left && separator.right <= second!.left, 'between them')

    await otp.typeIn('1234')
    assert.deepEqual(otp.chars, ['1', '2', '3', '4', '', ''], 'one code across the groups')
    assert.strictEqual(otp.activeIndex, 4)
    await a11yAudit()
  })
})
