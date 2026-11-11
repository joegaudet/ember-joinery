import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TabsHarness } from '@ember-joinery/test-support'
import TabsDisabled from 'docs-app/examples/tabs-disabled'

module('Example | tabs-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('the disabled tab can not be selected or reached', async function (assert) {
    await render(<template><TabsDisabled /></template>)
    const tabs = new TabsHarness()
    assert.true(tabs.isDisabled('settings'))
    assert.strictEqual(tabs.label('settings'), 'Disabled')
    assert.strictEqual(getComputedStyle(tabs.trigger('settings')).opacity, '0.5')

    await tabs.select('settings')
    assert.strictEqual(tabs.selected, 'home')
    await tabs.focus('home')
    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.focused, 'home', 'the arrows pass it by')
    await a11yAudit()
  })
})
