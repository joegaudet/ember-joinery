import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarGridFill from 'docs-app/examples/chart-radar-grid-fill'

module('Example | chart-radar-grid-fill', function (hooks) {
  setupRenderingTest(hooks)

  test('filled polygon rings', async function (assert) {
    await render(<template><ChartRadarGridFill /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Grid Filled')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    const grid = chart.polarGrid!
    assert.strictEqual(grid.type, 'polygon')
    assert.dom(grid.rings[2]).hasClass('opacity-20')
    assert.dom(grid.spokes[2]).hasClass('opacity-20')
    await a11yAudit()
  })
})
