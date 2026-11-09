import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness, FieldHarness, LabelHarness } from '@ember-joinery/test-support'
import CheckboxDisabled from 'docs-app/examples/checkbox-disabled'

module('Example | checkbox-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('a disabled checkbox, its field dimmed', async function (assert) {
    await render(<template><CheckboxDisabled /></template>)
    const field = new FieldHarness()
    const notifications = field.find(CheckboxHarness)

    assert.true(field.isDisabled)
    assert.true(notifications.isDisabled)
    assert.strictEqual(getComputedStyle(field.labelElement!).opacity, '0.5')
    assert.strictEqual(getComputedStyle(notifications.element).opacity, '0.5')
    await field.find(LabelHarness).click()
    assert.false(notifications.isChecked, 'a press on its label changes nothing')
    await a11yAudit()
  })
})
