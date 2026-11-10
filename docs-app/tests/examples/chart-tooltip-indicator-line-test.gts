import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartTooltipIndicatorLine from 'docs-app/examples/chart-tooltip-indicator-line'

module('Example | chart-tooltip-indicator-line', function (hooks) {
  setupRenderingTest(hooks)

  test('a line indicator', async function (assert) {
    await render(<template><ChartTooltipIndicatorLine /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Tooltip - Line Indicator')
    assert.strictEqual(card.description, 'Tooltip with line indicator.')
    const chart = card.find(ChartHarness)
    assert.strictEqual(chart.tooltip?.indicator, 'line')
    assert.deepEqual(chart.tooltip?.entryValues, ['380', '420'])
    await a11yAudit()
  })
})
