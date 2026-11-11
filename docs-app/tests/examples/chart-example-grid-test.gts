import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartExampleGrid from 'docs-app/examples/chart-example-grid'

module('Example | chart-example-grid', function (hooks) {
  setupRenderingTest(hooks)

  test('a grid behind the bars', async function (assert) {
    await render(<template><ChartExampleGrid /></template>)
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
    assert.true(chart.gridLines.horizontal.length > 1, 'horizontal lines')
    assert.deepEqual(chart.gridLines.vertical, [], 'vertical={false}')
    await a11yAudit()
  })
})
