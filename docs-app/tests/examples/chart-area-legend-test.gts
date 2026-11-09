import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartAreaLegend from 'docs-app/examples/chart-area-legend'

module('Example | chart-area-legend', function (hooks) {
  setupRenderingTest(hooks)

  test('stacked areas with a legend', async function (assert) {
    await render(<template><ChartAreaLegend /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Area Chart - Legend')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(ChartHarness)
    assert.deepEqual(chart.legend!.labels, ['Desktop', 'Mobile'])
    assert.strictEqual(
      chart.legend!.items[0]!.swatch!.style.backgroundColor,
      'var(--color-desktop)',
    )
    const legend = chart.wrapper.querySelector<HTMLElement>('.recharts-legend-wrapper')!
    assert.ok(
      chart.plot.y + chart.plot.height <= chart.height - legend.offsetHeight,
      'the legend takes room below the plot',
    )
    await a11yAudit()
  })
})
