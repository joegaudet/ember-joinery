import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartTooltipIcons from 'docs-app/examples/chart-tooltip-icons'

module('Example | chart-tooltip-icons', function (hooks) {
  setupRenderingTest(hooks)

  test("each entry's icon, in place of its indicator", async function (assert) {
    await render(<template><ChartTooltipIcons /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Tooltip - Icons')
    assert.strictEqual(card.description, 'Tooltip with icons.')
    const chart = card.find(ChartHarness)
    const items = chart.tooltip!.items
    assert.deepEqual(
      items.map(item => item.indicator),
      [null, null],
    )
    assert.strictEqual(chart.tooltip!.element.querySelectorAll('svg').length, 2, 'the two icons')
    assert.strictEqual(chart.tooltip?.label, null)
    await a11yAudit()
  })
})
