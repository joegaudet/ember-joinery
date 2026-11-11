import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartAreaStackedExpand from 'docs-app/examples/chart-area-stacked-expand'

module('Example | chart-area-stacked-expand', function (hooks) {
  setupRenderingTest(hooks)

  test('three areas stacked to 100%', async function (assert) {
    await render(<template><ChartAreaStackedExpand /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Area Chart - Stacked Expanded')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6months')
    const chart = card.find(ChartHarness)
    assert.deepEqual(
      chart.series.map(series => series.key),
      ['other', 'mobile', 'desktop'],
    )
    assert.true(
      chart.seriesFor('desktop').points.every(point => point.y === chart.plot.y),
      'the top area reaches 100% in every month',
    )
    await chart.hover(0)
    assert.deepEqual(chart.tooltip!.names, ['Desktop', 'Mobile', 'Other'])
    assert.deepEqual(chart.tooltip!.entryValues, ['186', '80', '45'])
    await a11yAudit()
  })
})
