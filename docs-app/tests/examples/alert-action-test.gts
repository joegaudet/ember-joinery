import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertHarness, ButtonHarness } from '@ember-joinery/test-support'
import AlertAction from 'docs-app/examples/alert-action'

module('Example | alert-action', function (hooks) {
  setupRenderingTest(hooks)

  test('an extra-small button in the top corner', async function (assert) {
    await render(<template><AlertAction /></template>)
    const alert = new AlertHarness()
    assert.strictEqual(alert.title, 'Dark mode is now available')
    assert.false(alert.hasIcon)
    const enable = alert.find(ButtonHarness)
    assert.strictEqual(enable.label, 'Enable')
    assert.strictEqual(enable.size, 'xs')
    assert.strictEqual(enable.variant, 'default')

    const box = alert.element.getBoundingClientRect()
    const button = enable.element.getBoundingClientRect()
    assert.ok(button.left > box.left + box.width / 2, 'on the inline end')
    assert.ok(button.top < box.top + box.height / 2, 'at the top')
    assert.strictEqual(getComputedStyle(alert.element).paddingRight, '72px', 'room for it')
    await a11yAudit()
  })
})
