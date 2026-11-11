import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarLegend from 'docs-app/examples/chart-radar-legend'

module('Example | chart-radar-legend', function (hooks) {
  setupRenderingTest(hooks)

  test('two radars and their legend', async function (assert) {
    await render(<template><ChartRadarLegend /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Legend')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    assert.deepEqual(chart.legend?.labels, ['Desktop', 'Mobile'])
    assert.dom(chart.legend!.element).hasClass('mt-8')
    assert.deepEqual(
      chart.series.map(series => series.key),
      ['desktop', 'mobile'],
    )
    await a11yAudit()
  })
})
