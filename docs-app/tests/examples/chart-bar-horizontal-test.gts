import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartBarHorizontal from 'docs-app/examples/chart-bar-horizontal'

module('Example | chart-bar-horizontal', function (hooks) {
  setupRenderingTest(hooks)

  test('the months down the y-axis, each bar running right', async function (assert) {
    await render(<template><ChartBarHorizontal /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Bar Chart - Horizontal')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.deepEqual(chart.yTicks, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'])
    assert.deepEqual(chart.xTicks, [], 'the x-axis is hidden')
    const [january, february] = chart.bars('desktop').map(bar => bar.getBoundingClientRect())
    assert.true(january!.top < february!.top, 'January above February')
    assert.true(february!.width > january!.width, 'February (305) longer than January (186)')

    await chart.hover(1)
    assert.deepEqual(chart.tooltip!.entryValues, ['305'])
    await a11yAudit()
  })
})
