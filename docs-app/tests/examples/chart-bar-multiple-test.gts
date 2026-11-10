import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartBarMultiple from 'docs-app/examples/chart-bar-multiple'

module('Example | chart-bar-multiple', function (hooks) {
  setupRenderingTest(hooks)

  test('desktop and mobile side by side, with a dashed indicator', async function (assert) {
    await render(<template><ChartBarMultiple /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Bar Chart - Multiple')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.deepEqual(
      chart.series.map(series => series.key),
      ['desktop', 'mobile'],
    )
    const [desktop] = chart.bars('desktop')
    const [mobile] = chart.bars('mobile')
    assert.true(
      desktop!.getBoundingClientRect().right <= mobile!.getBoundingClientRect().left,
      "January's mobile bar beside its desktop bar",
    )

    await chart.hover(3)
    assert.strictEqual(chart.tooltip!.indicator, 'dashed')
    assert.strictEqual(chart.tooltip!.label, 'April')
    assert.deepEqual(chart.tooltip!.names, ['Desktop', 'Mobile'])
    assert.deepEqual(chart.tooltip!.entryValues, ['73', '190'])
    await a11yAudit()
  })
})
