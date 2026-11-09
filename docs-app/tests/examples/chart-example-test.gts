import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartExample from 'docs-app/examples/chart-example'

module('Example | chart-example', function (hooks) {
  setupRenderingTest(hooks)

  test('two bars a month, from the config', async function (assert) {
    await render(<template><ChartExample /></template>)
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
    assert.deepEqual(chart.gridLines, { horizontal: [], vertical: [] }, 'no grid')
    assert.deepEqual(chart.xTicks, [], 'no axis')
    await a11yAudit()
  })
})
