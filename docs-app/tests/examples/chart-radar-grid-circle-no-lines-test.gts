import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarGridCircleNoLines from 'docs-app/examples/chart-radar-grid-circle-no-lines'

module('Example | chart-radar-grid-circle-no-lines', function (hooks) {
  setupRenderingTest(hooks)

  test('round rings without spokes', async function (assert) {
    await render(<template><ChartRadarGridCircleNoLines /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Grid Circle - No lines')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    assert.strictEqual(chart.polarGrid?.type, 'circle')
    assert.deepEqual(chart.polarGrid?.spokes, [], 'radialLines={{false}}')
    assert.strictEqual(chart.dots('desktop').length, 6)
    await a11yAudit()
  })
})
