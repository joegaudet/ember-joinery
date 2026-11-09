import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartExampleLegend from 'docs-app/examples/chart-example-legend'

module('Example | chart-example-legend', function (hooks) {
  setupRenderingTest(hooks)

  test('a legend under the bars', async function (assert) {
    await render(<template><ChartExampleLegend /></template>)
    const chart = new ChartHarness()
    assert.deepEqual(
      chart.series.map(series => [series.key, series.type, series.fill]),
      [
        ['desktop', 'bar', 'var(--color-desktop)'],
        ['mobile', 'bar', 'var(--color-mobile)'],
      ],
    )
    assert.strictEqual(chart.bars('desktop').length, 6)
    assert.strictEqual(chart.color('desktop'), '#2563eb')
    assert.deepEqual(chart.legend!.labels, ['Desktop', 'Mobile'])
    await chart.hover(5)
    assert.strictEqual(chart.tooltip!.label, 'June')
    await a11yAudit()
  })
})
