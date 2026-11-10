import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarGridCircle from 'docs-app/examples/chart-radar-grid-circle'

module('Example | chart-radar-grid-circle', function (hooks) {
  setupRenderingTest(hooks)

  test('round rings, with dots', async function (assert) {
    await render(<template><ChartRadarGridCircle /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Grid Circle')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    assert.strictEqual(chart.polarGrid?.type, 'circle')
    assert.strictEqual(chart.polarGrid?.spokes.length, 6, 'a spoke per month')
    assert.strictEqual(chart.dots('desktop').length, 6)
    await chart.hover(2)
    assert.strictEqual(chart.tooltip?.label, null, 'hideLabel')
    assert.deepEqual(chart.tooltip?.entryValues, ['237'])
    await a11yAudit()
  })
})
