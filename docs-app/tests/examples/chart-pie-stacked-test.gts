import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartPieStacked from 'docs-app/examples/chart-pie-stacked'

module('Example | chart-pie-stacked', function (hooks) {
  setupRenderingTest(hooks)

  test('desktop inside, mobile in a ring around it, each month by colour', async function (assert) {
    await render(<template><ChartPieStacked /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Pie Chart - Stacked')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.deepEqual(
      chart.series.map(series => series.key),
      ['desktop', 'mobile'],
    )
    assert.deepEqual(
      chart.sectors('mobile').map(sector => sector.getAttribute('fill')),
      [
        'var(--color-january)',
        'var(--color-february)',
        'var(--color-march)',
        'var(--color-april)',
        'var(--color-may)',
      ],
    )

    await chart.hover(1, 'mobile')
    assert.strictEqual(chart.tooltip!.indicator, 'line')
    assert.strictEqual(chart.tooltip!.label, 'Mobile', "the labelFormatter names the pie's data")
    assert.deepEqual(chart.tooltip!.names, ['February'], 'nameKey="month"')
    assert.deepEqual(chart.tooltip!.entryValues, ['200'])
    await chart.hover(0, 'desktop')
    assert.strictEqual(chart.tooltip!.label, 'Desktop')
    await a11yAudit()
  })
})
