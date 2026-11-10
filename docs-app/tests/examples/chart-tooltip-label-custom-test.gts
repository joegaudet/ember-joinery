import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartTooltipLabelCustom from 'docs-app/examples/chart-tooltip-label-custom'

module('Example | chart-tooltip-label-custom', function (hooks) {
  setupRenderingTest(hooks)

  test("the label from the config's activities", async function (assert) {
    await render(<template><ChartTooltipLabelCustom /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Tooltip - Custom label')
    assert.strictEqual(card.description, 'Tooltip with custom label from chartConfig.')
    const chart = card.find(ChartHarness)
    assert.strictEqual(chart.tooltip?.label, 'Activities')
    assert.strictEqual(chart.tooltip?.indicator, 'line')
    await a11yAudit()
  })
})
