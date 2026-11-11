import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarLabelCustom from 'docs-app/examples/chart-radar-label-custom'

module('Example | chart-radar-label-custom', function (hooks) {
  setupRenderingTest(hooks)

  test("each month's values over its name", async function (assert) {
    await render(<template><ChartRadarLabelCustom /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Custom Label')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    assert.deepEqual(chart.angleTicks, [
      '186/80January',
      '305/200February',
      '237/120March',
      '73/190April',
      '209/130May',
      '214/140June',
    ])
    const [january] = Array.from(chart.angleAxis!.querySelectorAll('text'))
    assert.dom(january).hasAttribute('font-size', '13').hasAttribute('font-weight', '500')
    assert.strictEqual(chart.series.length, 2)
    await a11yAudit()
  })
})
