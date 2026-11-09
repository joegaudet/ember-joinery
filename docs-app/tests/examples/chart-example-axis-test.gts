import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartExampleAxis from 'docs-app/examples/chart-example-axis'

module('Example | chart-example-axis', function (hooks) {
  setupRenderingTest(hooks)

  test('an x-axis with short month names', async function (assert) {
    await render(<template><ChartExampleAxis /></template>)
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
    assert.deepEqual(chart.xTicks, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'])
    await a11yAudit()
  })
})
