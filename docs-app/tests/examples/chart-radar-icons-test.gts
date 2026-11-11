import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarIcons from 'docs-app/examples/chart-radar-icons'

module('Example | chart-radar-icons', function (hooks) {
  setupRenderingTest(hooks)

  test("the legend shows each series' icon", async function (assert) {
    await render(<template><ChartRadarIcons /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Icons')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    assert.deepEqual(chart.legend?.labels, ['Desktop', 'Mobile'])
    assert.deepEqual(
      chart.legend?.items.map(item => item.swatch),
      [null, null],
      'icons, not swatches',
    )
    assert.dom(chart.legend!.element).hasClass('mt-8')
    await chart.hover(3)
    assert.strictEqual(chart.tooltip?.indicator, 'line')
    assert.deepEqual(chart.tooltip?.entryValues, ['73', '190'])
    await a11yAudit()
  })
})
