import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarGridCircleFill from 'docs-app/examples/chart-radar-grid-circle-fill'

module('Example | chart-radar-grid-circle-fill', function (hooks) {
  setupRenderingTest(hooks)

  test('filled round rings', async function (assert) {
    await render(<template><ChartRadarGridCircleFill /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Grid Circle Filled')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    const grid = chart.polarGrid!
    assert.strictEqual(grid.type, 'circle')
    assert.dom(grid.rings[4]).hasClass('opacity-20').hasClass('fill-(--color-desktop)')
    assert.dom(chart.polygon('desktop')).hasAttribute('fill-opacity', '0.5')
    await a11yAudit()
  })
})
