import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartPieLegend from 'docs-app/examples/chart-pie-legend'

module('Example | chart-pie-legend', function (hooks) {
  setupRenderingTest(hooks)

  test('a legend names each browser, under the pie', async function (assert) {
    await render(<template><ChartPieLegend /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Pie Chart - Legend')
    const chart = card.find(ChartHarness)
    const legend = chart.legend!
    assert.deepEqual(legend.labels, ['Chrome', 'Safari', 'Firefox', 'Edge', 'Other'])
    assert.dom(legend.element).hasClass('flex-wrap').hasClass('-translate-y-2')
    assert.true(
      legend.items[0]!.swatch!.getAttribute('style')!.includes('var(--color-chrome)'),
      "each swatch in its row's fill",
    )
    assert.false(chart.isTooltipVisible, 'no tooltip')
    assert.true(chart.plot.height < chart.height - 10, 'the legend takes room from the pie')
    await a11yAudit()
  })
})
