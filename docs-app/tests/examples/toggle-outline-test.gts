import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleHarness } from '@ember-joinery/test-support'
import ToggleOutline from 'docs-app/examples/toggle-outline'

module('Example | toggle-outline', function (hooks) {
  setupRenderingTest(hooks)

  test('two outline toggles with an icon and a label', async function (assert) {
    await render(<template><ToggleOutline /></template>)
    const [italic, bold] = ToggleHarness.findAll()
    assert.strictEqual(italic!.label, 'Toggle italic')
    assert.strictEqual(italic!.text, 'Italic')
    assert.strictEqual(bold!.variant, 'outline')
    await bold!.toggle()
    assert.true(bold!.isPressed)
    assert.false(italic!.isPressed)
    await a11yAudit()
  })
})
