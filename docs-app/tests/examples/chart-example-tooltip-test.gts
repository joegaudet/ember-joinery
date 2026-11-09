import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartExampleTooltip from 'docs-app/examples/chart-example-tooltip'

module('Example | chart-example-tooltip', function (hooks) {
  setupRenderingTest(hooks)

  test('a tooltip on hover', async function (assert) {
    await render(<template><ChartExampleTooltip /></template>)
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
    await chart.hover(0)
    const tooltip = chart.tooltip!
    assert.strictEqual(tooltip.label, 'January')
    assert.deepEqual(tooltip.names, ['Desktop', 'Mobile'])
    assert.deepEqual(tooltip.entryValues, ['186', '80'])
    assert.dom(chart.cursor).hasClass('recharts-rectangle', 'a band under the pointer')
    await a11yAudit()
  })
})
