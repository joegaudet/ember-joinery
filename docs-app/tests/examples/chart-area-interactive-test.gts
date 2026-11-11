import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness, SelectHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartAreaInteractive from 'docs-app/examples/chart-area-interactive'

module('Example | chart-area-interactive', function (hooks) {
  setupRenderingTest(hooks)

  test('stacked areas over three months, and a select of the time range', async function (assert) {
    await render(<template><ChartAreaInteractive /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Area Chart - Interactive')
    assert.strictEqual(card.description, 'Showing total visitors for the last 3 months')
    const chart = card.find(ChartHarness)
    const range = card.find(SelectHarness)
    assert.strictEqual(range.label, 'Select a value')
    assert.strictEqual(range.value, '90d')

    const mobile = chart.seriesFor('mobile')
    const desktop = chart.seriesFor('desktop')
    assert.strictEqual(mobile.points.length, 91, 'April to June')
    assert.strictEqual(mobile.fill, 'url(#fillMobile)')
    assert.strictEqual(desktop.stroke, 'var(--color-desktop)')
    mobile.points.forEach((point, i) => {
      assert.ok(desktop.points[i]!.y <= point.y, `desktop sits on mobile in row ${i}`)
    })
    assert.deepEqual(chart.legend!.labels, ['Desktop', 'Mobile'])
    assert.true(chart.xTicks.length < 91, 'minTickGap={{32}} drops the ticks that would crowd')

    await chart.hover(90)
    assert.strictEqual(chart.tooltip!.label, 'Jun 30')
    assert.deepEqual(chart.tooltip!.names, ['Desktop', 'Mobile'])
    assert.strictEqual(chart.tooltip!.indicator, 'dot')
    await chart.unhover()
    await a11yAudit()

    await range.open()
    assert.deepEqual(range.optionTexts, ['Last 3 months', 'Last 30 days', 'Last 7 days'])
    await range.select('30d')
    assert.strictEqual(range.valueText, 'Last 30 days')
    assert.strictEqual(chart.seriesFor('mobile').points.length, 31, 'the last 30 days')
    await range.open()
    await range.select('7d')
    assert.strictEqual(chart.seriesFor('mobile').points.length, 8, 'the last 7 days')
    await a11yAudit()
  })
})
