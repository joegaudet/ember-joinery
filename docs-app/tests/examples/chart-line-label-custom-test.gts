import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartLineLabelCustom from 'docs-app/examples/chart-line-label-custom'

module('Example | chart-line-label-custom', function (hooks) {
  setupRenderingTest(hooks)

  test("each point labelled with its browser's config label", async function (assert) {
    await render(<template><ChartLineLabelCustom /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Line Chart - Custom Label')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.deepEqual(chart.labels('visitors'), ['Chrome', 'Safari', 'Firefox', 'Edge', 'Other'])
    assert.deepEqual(chart.xTicks, [], 'no x-axis')
    await chart.hover(0)
    assert.deepEqual(chart.tooltip!.names, ['Visitors'], 'nameKey="visitors"')
    await a11yAudit()
  })
})
