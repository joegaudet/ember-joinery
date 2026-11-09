import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SelectHarness } from '@ember-joinery/test-support'
import SelectDisabled from 'docs-app/examples/select-disabled'

module('Example | select-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('the select is disabled: its trigger can’t be pressed or focused', async function (assert) {
    await render(<template><SelectDisabled /></template>)
    const select = new SelectHarness()
    assert.true(select.isDisabled)
    assert.dom(select.trigger).isDisabled()
    assert.strictEqual(getComputedStyle(select.trigger).opacity, '0.5')
    assert.false(select.isOpen)
    assert.strictEqual(select.valueText, 'Select a fruit')
    await a11yAudit()
  })
})
