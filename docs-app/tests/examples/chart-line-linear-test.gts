import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartLineLinear from 'docs-app/examples/chart-line-linear'

module('Example | chart-line-linear', function (hooks) {
  setupRenderingTest(hooks)

  test('straight lines between the points', async function (assert) {
    await render(<template><ChartLineLinear /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Line Chart - Linear')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const line = chart.seriesFor('desktop')
    assert.false(line.path!.includes('C'), 'no curves')
    assert.strictEqual(line.points.length, 6)
    await chart.hover(0)
    assert.deepEqual(chart.tooltip!.entryValues, ['186'])
    await a11yAudit()
  })
})
