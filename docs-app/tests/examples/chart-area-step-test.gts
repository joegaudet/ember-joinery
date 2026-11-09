import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartAreaStep from 'docs-app/examples/chart-area-step'

module('Example | chart-area-step', function (hooks) {
  setupRenderingTest(hooks)

  test('steps between the points, and the config icon in the tooltip', async function (assert) {
    await render(<template><ChartAreaStep /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Area Chart - Step')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(ChartHarness)
    const area = chart.seriesFor('desktop')
    assert.false(area.path!.includes('C'), 'type="step": no curves')
    const [first, second] = area.points
    assert.ok(first && second && first.y !== second.y, 'one step per month')
    await chart.hover(0)
    const [item] = chart.tooltip!.items
    assert.strictEqual(item!.indicator, null, "the config's icon in place of the indicator")
    assert.dom(chart.tooltip!.element.querySelector('svg')).exists()
    await a11yAudit()
  })
})
