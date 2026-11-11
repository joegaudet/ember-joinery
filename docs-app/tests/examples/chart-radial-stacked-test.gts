import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadialStacked from 'docs-app/examples/chart-radial-stacked'

module('Example | chart-radial-stacked', function (hooks) {
  setupRenderingTest(hooks)

  test('mobile and desktop stacked, the total in the middle', async function (assert) {
    await render(<template><ChartRadialStacked /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radial Chart - Stacked')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(PolarChartHarness)
    assert.dom(chart.radialBars('mobile')[0]).hasAttribute('fill', 'var(--color-mobile)')
    assert.dom(chart.radialBars('desktop')[0]).hasAttribute('fill', 'var(--color-desktop)')
    assert.dom(chart.seriesFor('desktop').element).hasClass('stroke-transparent')
    assert.dom(chart.radiusAxis).hasText('1,830Visitors')
    await chart.hover(0)
    assert.deepEqual(chart.tooltip?.names, ['Desktop', 'Mobile'])
    assert.deepEqual(chart.tooltip?.entryValues, ['1,260', '570'])
    await a11yAudit()
  })
})
