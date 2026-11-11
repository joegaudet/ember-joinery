import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TabsHarness } from '@ember-joinery/test-support'
import TabsHeadless from 'docs-app/examples/tabs-headless'

module('Example | tabs-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('the arrows move focus, and Enter selects', async function (assert) {
    await render(<template><TabsHeadless /></template>)
    const tabs = new TabsHarness()
    assert.strictEqual(tabs.listLabel, 'Install with your package manager')
    assert.strictEqual(tabs.panelText, 'npm add @ember-joinery/primitives')

    await tabs.focus('npm')
    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.focused, 'pnpm')
    assert.strictEqual(tabs.selected, 'npm', 'manual: focus alone selects nothing')
    await tabs.press('Enter')
    assert.strictEqual(tabs.panelText, 'pnpm add @ember-joinery/primitives')
    await a11yAudit()
  })
})
