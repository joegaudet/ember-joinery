import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, InputGroupHarness, SpinnerHarness } from '@ember-joinery/test-support'
import SpinnerInputGroup from 'docs-app/examples/spinner-input-group'

module('Example | spinner-input-group', function (hooks) {
  setupRenderingTest(hooks)

  test('a disabled input and textarea, validating, each with a spinner', async function (assert) {
    await render(<template><SpinnerInputGroup /></template>)
    const [input, textarea] = InputGroupHarness.findAll()
    assert.true(input!.isDisabled)
    assert.true(textarea!.isDisabled)
    assert.strictEqual(getComputedStyle(input!.element).opacity, '0.5', 'has-disabled:opacity-50')
    assert.true(input!.find(SpinnerHarness).exists)
    assert.strictEqual(textarea!.addonText('block-end'), 'Validating... Send')
    assert.strictEqual(textarea!.find(ButtonHarness).label, 'Send')
    await a11yAudit()
  })
})
