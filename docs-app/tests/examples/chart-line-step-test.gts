import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartLineStep from 'docs-app/examples/chart-line-step'

module('Example | chart-line-step', function (hooks) {
  setupRenderingTest(hooks)

  test('steps between the points', async function (assert) {
    await render(<template><ChartLineStep /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Line Chart - Step')
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
