import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartLineMultiple from 'docs-app/examples/chart-line-multiple'

module('Example | chart-line-multiple', function (hooks) {
  setupRenderingTest(hooks)

  test('two lines, both in the tooltip', async function (assert) {
    await render(<template><ChartLineMultiple /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Line Chart - Multiple')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.deepEqual(
      chart.series.map(series => [series.key, series.stroke]),
      [
        ['desktop', 'var(--color-desktop)'],
        ['mobile', 'var(--color-mobile)'],
      ],
    )
    await chart.hover(3)
    assert.strictEqual(chart.tooltip!.label, 'April')
    assert.deepEqual(chart.tooltip!.names, ['Desktop', 'Mobile'])
    assert.deepEqual(chart.tooltip!.entryValues, ['73', '190'])
    await a11yAudit()
  })
})
