import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartAreaLinear from 'docs-app/examples/chart-area-linear'

module('Example | chart-area-linear', function (hooks) {
  setupRenderingTest(hooks)

  test('straight lines between the points, and a tooltip without a label', async function (assert) {
    await render(<template><ChartAreaLinear /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Area Chart - Linear')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(ChartHarness)
    const area = chart.seriesFor('desktop')
    assert.false(area.path!.includes('C'), 'type="linear": no curves')
    await chart.hover(3)
    assert.strictEqual(chart.tooltip!.label, null, 'hideLabel')
    assert.strictEqual(chart.tooltip!.indicator, 'dot')
    assert.deepEqual(chart.tooltip!.entryValues, ['73'])
    await a11yAudit()
  })
})
