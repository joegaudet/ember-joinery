import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, LabelHarness, SwitchHarness } from '@ember-joinery/test-support'
import SwitchDisabled from 'docs-app/examples/switch-disabled'

module('Example | switch-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('a disabled switch, its label dimmed', async function (assert) {
    await render(<template><SwitchDisabled /></template>)
    const field = new FieldHarness()
    const toggle = field.find(SwitchHarness)

    assert.true(toggle.isDisabled)
    assert.true(field.isDisabled)
    assert.strictEqual(getComputedStyle(field.labelElement!).opacity, '0.5')
    await field.find(LabelHarness).click()
    assert.false(toggle.isChecked)
    await a11yAudit()
  })
})
