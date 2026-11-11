import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleHarness } from '@ember-joinery/test-support'
import ToggleText from 'docs-app/examples/toggle-text'

module('Example | toggle-text', function (hooks) {
  setupRenderingTest(hooks)

  test('a toggle with an icon and text', async function (assert) {
    await render(<template><ToggleText /></template>)
    const toggle = new ToggleHarness()
    assert.strictEqual(toggle.text, 'Italic')
    assert.strictEqual(toggle.variant, 'default')
    await toggle.toggle()
    assert.strictEqual(toggle.state, 'on')
    await a11yAudit()
  })
})
