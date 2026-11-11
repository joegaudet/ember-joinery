import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartTooltipAdvanced from 'docs-app/examples/chart-tooltip-advanced'

module('Example | chart-tooltip-advanced', function (hooks) {
  setupRenderingTest(hooks)

  test('each entry in kcal, and the total', async function (assert) {
    await render(<template><ChartTooltipAdvanced /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Tooltip - Advanced')
    assert.strictEqual(card.description, 'Tooltip with custom formatter and total.')
    const chart = card.find(ChartHarness)
    assert.strictEqual(chart.tooltip?.text, 'Running 380 kcal Swimming 420 kcal Total 800 kcal')
    assert.dom(chart.tooltip!.element).hasClass('w-[180px]')
    await chart.hover(4)
    assert.strictEqual(chart.tooltip?.text, 'Running 600 kcal Swimming 350 kcal Total 950 kcal')
    await a11yAudit()
  })
})
