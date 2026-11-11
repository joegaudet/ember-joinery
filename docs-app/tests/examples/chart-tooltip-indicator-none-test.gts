import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartTooltipIndicatorNone from 'docs-app/examples/chart-tooltip-indicator-none'

module('Example | chart-tooltip-indicator-none', function (hooks) {
  setupRenderingTest(hooks)

  test('no indicators', async function (assert) {
    await render(<template><ChartTooltipIndicatorNone /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Tooltip - No Indicator')
    assert.strictEqual(card.description, 'Tooltip with no indicator.')
    const chart = card.find(ChartHarness)
    assert.deepEqual(
      chart.tooltip?.items.map(item => item.indicator),
      [null, null],
    )
    assert.strictEqual(chart.tooltip?.label, '2024-07-16')
    await a11yAudit()
  })
})
