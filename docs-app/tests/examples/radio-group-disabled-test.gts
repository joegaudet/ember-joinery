import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, RadioGroupHarness, tab } from '@ember-joinery/test-support'
import RadioGroupDisabled from 'docs-app/examples/radio-group-disabled'

module('Example | radio-group-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('a disabled choice, dimmed, which the arrow keys pass over', async function (assert) {
    await render(<template><RadioGroupDisabled /></template>)
    const group = new RadioGroupHarness()
    const [disabled] = FieldHarness.findAll()

    assert.true(group.isItemDisabled('option1'))
    assert.true(disabled!.isDisabled)
    assert.strictEqual(getComputedStyle(disabled!.labelElement!).opacity, '0.5')
    assert.strictEqual(group.value, 'option2')
    await tab()
    await group.press('ArrowDown')
    await group.press('ArrowDown')
    assert.strictEqual(group.value, 'option2', 'round past the disabled one')
    await a11yAudit()
  })
})
