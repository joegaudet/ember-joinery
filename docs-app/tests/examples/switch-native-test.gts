import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SwitchHarness } from '@ember-joinery/test-support'
import SwitchNative from 'docs-app/examples/switch-native'

module('Example | switch-native', function (hooks) {
  setupRenderingTest(hooks)

  test('an airplane mode switch, which its label toggles', async function (assert) {
    await render(<template><SwitchNative /></template>)
    const airplane = new SwitchHarness()

    assert.strictEqual(airplane.label, 'Airplane Mode')
    assert.strictEqual(airplane.size, 'default')
    assert.false(airplane.isChecked)
    await airplane.toggle()
    assert.true(airplane.isChecked)
    await click('label[for="airplane-mode-native"]')
    assert.false(airplane.isChecked, 'a click on the label toggles it')
    await a11yAudit()
  })
})
