import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, press, pressEscape, pressOutside } from '@ember-joinery/test-support'
import DismissNested from 'docs-app/examples/dismiss-nested'

/** The example: a button, its panel, and the nested panel the panel's button opens. */
class NestedPanelsHarness extends Harness {
  static component = 'nested-panels'

  get panel() {
    return this.queryPart('panel')
  }

  get morePanel() {
    return this.queryPart('more-panel')
  }

  async openBoth() {
    await click(this.part('trigger'))
    await click(this.part('more-trigger'))
  }
}

module('Example | dismiss-nested', function (hooks) {
  setupRenderingTest(hooks)

  test('Escape closes the top panel only', async function (assert) {
    await render(<template><DismissNested /></template>)
    const panels = new NestedPanelsHarness()
    await panels.openBoth()

    await pressEscape()
    assert.strictEqual(panels.morePanel, null, 'the nested panel closed')
    assert.dom(panels.panel).exists('the first stayed')

    await pressEscape()
    assert.strictEqual(panels.panel, null)
    await a11yAudit()
  })

  test('a press in the nested panel is inside both; outside, it closes both', async function (assert) {
    await render(<template><DismissNested /></template>)
    const panels = new NestedPanelsHarness()
    await panels.openBoth()

    await press(panels.morePanel!)
    assert.dom(panels.panel).exists()
    assert.dom(panels.morePanel).exists()

    await pressOutside()
    assert.strictEqual(panels.panel, null)
    assert.strictEqual(panels.morePanel, null)
    await a11yAudit()
  })
})
