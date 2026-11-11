import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartLineInteractive from 'docs-app/examples/chart-line-interactive'

module('Example | chart-line-interactive', function (hooks) {
  setupRenderingTest(hooks)

  test('the buttons switch the line between desktop and mobile', async function (assert) {
    await render(<template><ChartLineInteractive /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Line Chart - Interactive')
    const chart = card.find(ChartHarness)
    const [desktop, mobile] = Array.from(card.header.querySelectorAll('button'))
    assert.strictEqual(desktop!.textContent!.replace(/\s+/g, ' ').trim(), 'Desktop 24,828')
    assert.strictEqual(mobile!.textContent!.replace(/\s+/g, ' ').trim(), 'Mobile 25,010')
    assert.dom(desktop).hasAttribute('data-active', 'true')
    assert.strictEqual(chart.series[0]!.key, 'desktop')

    await click(mobile!)
    assert.dom(mobile).hasAttribute('data-active', 'true')
    assert.dom(desktop).hasAttribute('data-active', 'false')
    assert.strictEqual(chart.series[0]!.key, 'mobile', 'the chart shows mobile')
    assert.strictEqual(chart.series[0]!.stroke, 'var(--color-mobile)')
    assert.true(chart.xTicks.length < 91, 'minTickGap={{32}} drops the ticks that would crowd')

    await chart.hover(0)
    assert.deepEqual(chart.tooltip!.names, ['Page Views'], 'nameKey="views"')
    assert.true(chart.tooltip!.label!.endsWith('2024'), 'labelFormatter adds the year')
    await a11yAudit()
  })
})
