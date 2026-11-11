import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleHarness } from '@ember-joinery/test-support'
import ToggleDisabled from 'docs-app/examples/toggle-disabled'

module('Example | toggle-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('two disabled toggles, which a press leaves off', async function (assert) {
    await render(<template><ToggleDisabled /></template>)
    const toggles = ToggleHarness.findAll()
    assert.strictEqual(toggles.length, 2)
    for (const toggle of toggles) {
      assert.true(toggle.isDisabled)
      await toggle.toggle().catch(() => undefined)
      assert.false(toggle.isPressed)
    }
    assert.strictEqual(toggles[1]!.variant, 'outline')
    await a11yAudit()
  })
})
