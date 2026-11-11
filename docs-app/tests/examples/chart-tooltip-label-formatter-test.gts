import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartTooltipLabelFormatter from 'docs-app/examples/chart-tooltip-label-formatter'

module('Example | chart-tooltip-label-formatter', function (hooks) {
  setupRenderingTest(hooks)

  test('the date written out', async function (assert) {
    await render(<template><ChartTooltipLabelFormatter /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Tooltip - Label Formatter')
    assert.strictEqual(card.description, 'Tooltip with label formatter.')
    const chart = card.find(ChartHarness)
    assert.strictEqual(chart.tooltip?.label, 'July 16, 2024')
    await chart.hover(4)
    assert.strictEqual(chart.tooltip?.label, 'July 19, 2024')
    await a11yAudit()
  })
})
