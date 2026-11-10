import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartTooltipLabelNone from 'docs-app/examples/chart-tooltip-label-none'

module('Example | chart-tooltip-label-none', function (hooks) {
  setupRenderingTest(hooks)

  test('no label and no indicators', async function (assert) {
    await render(<template><ChartTooltipLabelNone /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Tooltip - No Label')
    assert.strictEqual(card.description, 'Tooltip with no label.')
    const chart = card.find(ChartHarness)
    assert.strictEqual(chart.tooltip?.label, null)
    assert.deepEqual(
      chart.tooltip?.items.map(item => item.indicator),
      [null, null],
    )
    assert.deepEqual(chart.tooltip?.names, ['Running', 'Swimming'])
    await a11yAudit()
  })
})
