import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TabsHarness } from '@ember-joinery/test-support'
import TabsUsage from 'docs-app/examples/tabs-usage'

module('Example | tabs-usage', function (hooks) {
  setupRenderingTest(hooks)

  test('each tab shows its own panel', async function (assert) {
    await render(<template><TabsUsage /></template>)
    const tabs = new TabsHarness()
    assert.strictEqual(tabs.selected, 'account')
    assert.strictEqual(tabs.panelText, 'Make changes to your account here.')
    assert.strictEqual(getComputedStyle(tabs.element).width, '400px', 'w-[400px]')

    await tabs.select('password')
    assert.strictEqual(tabs.panelText, 'Change your password here.')
    assert.false(tabs.isShown('account'))
    await a11yAudit()
  })
})
