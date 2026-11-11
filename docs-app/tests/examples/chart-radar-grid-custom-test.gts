import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarGridCustom from 'docs-app/examples/chart-radar-grid-custom'

module('Example | chart-radar-grid-custom', function (hooks) {
  setupRenderingTest(hooks)

  test('one ring at a given radius', async function (assert) {
    await render(<template><ChartRadarGridCustom /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Grid Custom')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    assert.deepEqual(chart.polarGrid?.radii, [90])
    assert.deepEqual(chart.polarGrid?.spokes, [])
    assert.dom(chart.polarGrid!.rings[0]).hasAttribute('stroke-width', '1')
    await a11yAudit()
  })
})
