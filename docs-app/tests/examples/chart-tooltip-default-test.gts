import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartTooltipDefault from 'docs-app/examples/chart-tooltip-default'

module('Example | chart-tooltip-default', function (hooks) {
  setupRenderingTest(hooks)

  test('shows the second day to begin with', async function (assert) {
    await render(<template><ChartTooltipDefault /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Tooltip - Default')
    assert.strictEqual(card.description, 'Default tooltip with ChartTooltipContent.')
    const chart = card.find(ChartHarness)
    assert.deepEqual(chart.xTicks, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
    assert.true(chart.isTooltipVisible, 'defaultIndex={1}')
    assert.strictEqual(chart.tooltip?.label, '2024-07-16')
    assert.deepEqual(chart.tooltip?.names, ['Running', 'Swimming'])
    assert.deepEqual(chart.tooltip?.entryValues, ['380', '420'])
    assert.strictEqual(chart.tooltip?.indicator, 'dot')
    await chart.hover(3)
    assert.strictEqual(chart.tooltip?.label, '2024-07-18')
    await a11yAudit()
  })
})
