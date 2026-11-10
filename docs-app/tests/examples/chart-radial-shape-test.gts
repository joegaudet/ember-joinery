import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadialShape from 'docs-app/examples/chart-radial-shape'

module('Example | chart-radial-shape', function (hooks) {
  setupRenderingTest(hooks)

  test('a bar over two rings, its value in the middle', async function (assert) {
    await render(<template><ChartRadialShape /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radial Chart - Shape')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(PolarChartHarness)
    const grid = chart.polarGrid!
    assert.deepEqual(grid.radii, [86, 74])
    assert.dom(grid.rings[0]).hasClass('first:fill-muted').hasAttribute('stroke', 'none')
    assert.strictEqual(chart.radialBars('visitors').length, 1)
    assert.dom(chart.radiusAxis).hasText('1,260Visitors')
    await a11yAudit()
  })
})
