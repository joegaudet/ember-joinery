import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, InputHarness } from '@ember-joinery/test-support'
import NativeValueForm from 'docs-app/examples/native-value-form'

module('Example | native-value-form', function (hooks) {
  setupRenderingTest(hooks)

  test('an input of your own keeps its value, reports it, and resets with its form', async function (assert) {
    await render(<template><NativeValueForm /></template>)
    const name = new InputHarness('name')
    const heard = () => find('[data-test-heard]')!.textContent!.trim()

    assert.strictEqual(name.value, 'Ada', 'from defaultValue')
    assert.strictEqual(getComputedStyle(name.element).height, '32px', "with Joinery's look")

    await name.fillIn('Grace')
    assert.strictEqual(heard(), 'Grace', 'onValueChange told the parent')

    await new ButtonHarness('reset').click()
    assert.strictEqual(name.value, 'Ada', 'the reset puts the default back')
    assert.strictEqual(heard(), 'Ada', 'and says so')
    await a11yAudit()
  })
})
