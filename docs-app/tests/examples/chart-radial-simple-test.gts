import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadialSimple from 'docs-app/examples/chart-radial-simple'

module('Example | chart-radial-simple', function (hooks) {
  setupRenderingTest(hooks)

  test('a bar round the chart for each browser', async function (assert) {
    await render(<template><ChartRadialSimple /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radial Chart')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(PolarChartHarness)
    assert.strictEqual(chart.layout, 'radial')
    const bars = chart.radialBars('visitors')
    assert.strictEqual(bars.length, 5)
    assert.dom(bars[0]).hasAttribute('fill', 'var(--color-chrome)')
    assert.strictEqual(chart.backgroundSectors.length, 5, 'a track behind each')
    await chart.hover(1)
    assert.strictEqual(chart.tooltip?.label, null, 'hideLabel')
    assert.deepEqual(chart.tooltip?.names, ['Safari'], 'named by browser')
    assert.deepEqual(chart.tooltip?.entryValues, ['200'])
    await a11yAudit()
  })
})
