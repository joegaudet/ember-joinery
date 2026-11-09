import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TabsHarness } from '@ember-joinery/test-support'
import TabsVertical from 'docs-app/examples/tabs-vertical'

module('Example | tabs-vertical', function (hooks) {
  setupRenderingTest(hooks)

  test('the tabs stack, and up and down move between them', async function (assert) {
    await render(<template><TabsVertical /></template>)
    const tabs = new TabsHarness()
    assert.strictEqual(tabs.orientation, 'vertical')
    assert.strictEqual(getComputedStyle(tabs.list).flexDirection, 'column')
    assert.strictEqual(tabs.selected, 'account')

    await tabs.focus('account')
    await tabs.press('ArrowDown')
    assert.strictEqual(tabs.selected, 'password')
    await tabs.press('ArrowDown')
    assert.strictEqual(tabs.selected, 'notifications')
    await tabs.press('ArrowDown')
    assert.strictEqual(tabs.selected, 'account', 'and round to the first')
    await a11yAudit()
  })
})
