import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarGridNone from 'docs-app/examples/chart-radar-grid-none'

module('Example | chart-radar-grid-none', function (hooks) {
  setupRenderingTest(hooks)

  test('no grid', async function (assert) {
    await render(<template><ChartRadarGridNone /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Grid None')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    assert.strictEqual(chart.polarGrid, null)
    assert.deepEqual(chart.angleTicks, ['January', 'February', 'March', 'April', 'May', 'June'])
    assert.strictEqual(chart.dots('desktop').length, 6)
    await a11yAudit()
  })
})
