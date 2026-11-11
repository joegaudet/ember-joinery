import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleHarness } from '@ember-joinery/test-support'
import ToggleHeadless from 'docs-app/examples/toggle-headless'

module('Example | toggle-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a toggle that shows its state', async function (assert) {
    await render(<template><ToggleHeadless /></template>)
    const toggle = new ToggleHarness()
    assert.strictEqual(toggle.text, 'Notifications off')
    assert.false(toggle.isPressed)
    await toggle.toggle()
    assert.true(toggle.isPressed)
    assert.strictEqual(toggle.state, 'on')
    await a11yAudit()
  })
})
