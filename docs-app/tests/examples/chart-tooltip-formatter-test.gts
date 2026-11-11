import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartTooltipFormatter from 'docs-app/examples/chart-tooltip-formatter'

module('Example | chart-tooltip-formatter', function (hooks) {
  setupRenderingTest(hooks)

  test('each entry in kcal', async function (assert) {
    await render(<template><ChartTooltipFormatter /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Tooltip - Formatter')
    assert.strictEqual(card.description, 'Tooltip with custom formatter .')
    const chart = card.find(ChartHarness)
    assert.strictEqual(chart.tooltip?.text, 'Running 380 kcal Swimming 420 kcal')
    await a11yAudit()
  })
})
