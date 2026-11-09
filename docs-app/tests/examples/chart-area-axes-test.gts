import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartAreaAxes from 'docs-app/examples/chart-area-axes'

module('Example | chart-area-axes', function (hooks) {
  setupRenderingTest(hooks)

  test('a y-axis with three ticks beside stacked areas', async function (assert) {
    await render(<template><ChartAreaAxes /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Area Chart - Axes')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(ChartHarness)
    assert.deepEqual(chart.xTicks, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'])
    assert.true(
      chart.yTicks.every(tick => ['0', '300', '600'].includes(tick)),
      'tickCount={3}: nice ticks over the stacked total',
    )
    assert.strictEqual(chart.yTicks.at(-1), '600')
    assert.strictEqual(chart.plot.x, 40, 'the y-axis is 60px wide, less the -20 margin')
    await a11yAudit()
  })
})
