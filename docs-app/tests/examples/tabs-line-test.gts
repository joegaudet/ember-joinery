import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TabsHarness } from '@ember-joinery/test-support'
import TabsLine from 'docs-app/examples/tabs-line'

module('Example | tabs-line', function (hooks) {
  setupRenderingTest(hooks)

  test('a line under the selected tab, and the arrows move it', async function (assert) {
    await render(<template><TabsLine /></template>)
    const tabs = new TabsHarness()
    assert.strictEqual(tabs.variant, 'line')
    assert.deepEqual(tabs.tabValues, ['overview', 'analytics', 'reports'])
    assert.strictEqual(tabs.selected, 'overview')
    assert.strictEqual(getComputedStyle(tabs.list).backgroundColor, 'rgba(0, 0, 0, 0)')

    await tabs.focus('overview')
    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.selected, 'analytics', 'focus selects, as the arrows move it')
    await tabs.select('reports')
    assert.strictEqual(tabs.selected, 'reports')
    await a11yAudit()
  })
})
