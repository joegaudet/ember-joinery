import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarDots from 'docs-app/examples/chart-radar-dots'

module('Example | chart-radar-dots', function (hooks) {
  setupRenderingTest(hooks)

  test('a dot at each point', async function (assert) {
    await render(<template><ChartRadarDots /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Dots')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    const dots = chart.dots('desktop')
    assert.strictEqual(dots.length, 6)
    assert
      .dom(dots[0])
      .hasAttribute('r', '4')
      .hasAttribute('fill-opacity', '1')
      .hasAttribute('fill', 'var(--color-desktop)')
    const [point] = chart.seriesFor('desktop').points
    assert.true(Math.abs(Number(dots[0]!.getAttribute('cy')) - point!.y) < 0.01, 'on the point')
    await a11yAudit()
  })
})
