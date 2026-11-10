import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarMultiple from 'docs-app/examples/chart-radar-multiple'

module('Example | chart-radar-multiple', function (hooks) {
  setupRenderingTest(hooks)

  test('desktop and mobile', async function (assert) {
    await render(<template><ChartRadarMultiple /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Multiple')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    assert.deepEqual(
      chart.series.map(series => series.key),
      ['desktop', 'mobile'],
    )
    await chart.hover(0)
    assert.strictEqual(chart.tooltip?.label, 'January')
    assert.deepEqual(chart.tooltip?.names, ['Desktop', 'Mobile'])
    assert.deepEqual(chart.tooltip?.entryValues, ['186', '80'])
    await a11yAudit()
  })
})
