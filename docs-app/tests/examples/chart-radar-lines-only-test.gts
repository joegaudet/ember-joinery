import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarLinesOnly from 'docs-app/examples/chart-radar-lines-only'

module('Example | chart-radar-lines-only', function (hooks) {
  setupRenderingTest(hooks)

  test('outlines with no fill', async function (assert) {
    await render(<template><ChartRadarLinesOnly /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Lines Only')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    assert
      .dom(chart.polygon('desktop'))
      .hasAttribute('fill-opacity', '0')
      .hasAttribute('stroke', 'var(--color-desktop)')
      .hasAttribute('stroke-width', '2')
    assert.dom(chart.polygon('mobile')).hasAttribute('stroke', 'var(--color-mobile)')
    assert.deepEqual(chart.polarGrid?.spokes, [])
    await chart.hover(5)
    assert.deepEqual(chart.tooltip?.entryValues, ['174', '204'])
    await a11yAudit()
  })
})
