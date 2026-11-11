import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SwitchHarness } from '@ember-joinery/test-support'
import SwitchHeadless from 'docs-app/examples/switch-headless'

module('Example | switch-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a switch with styles of its own, whose thumb slides when it is on', async function (assert) {
    await render(<template><SwitchHeadless /></template>)
    const wifi = new SwitchHarness()

    assert.strictEqual(wifi.label, 'Wi-Fi')
    assert.strictEqual(wifi.size, null, 'the headless switch has no sizes')
    assert.dom(wifi.thumb).hasAttribute('data-state', 'unchecked')

    await wifi.toggle()
    assert.true(wifi.isChecked)
    assert.dom(wifi.thumb).hasAttribute('data-state', 'checked')
    for (const animation of wifi.thumb!.getAnimations()) animation.finish()
    assert.strictEqual(getComputedStyle(wifi.thumb!).translate, '16px', 'translate-x-4')
    await a11yAudit()
  })
})
