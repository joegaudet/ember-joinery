import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartAreaDefault from 'docs-app/examples/chart-area-default'

module('Example | chart-area-default', function (hooks) {
  setupRenderingTest(hooks)

  test('a natural area over six months, with a line tooltip', async function (assert) {
    await render(<template><ChartAreaDefault /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Area Chart')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(ChartHarness)
    const area = chart.seriesFor('desktop')
    assert.strictEqual(area.type, 'area')
    assert.strictEqual(area.fill, 'var(--color-desktop)')
    assert.true(area.path!.includes('C'), 'a natural curve')
    assert.deepEqual(chart.xTicks, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'])
    assert.deepEqual(chart.gridLines.vertical, [], 'no vertical grid lines')

    await chart.hover(1)
    const tooltip = chart.tooltip!
    assert.strictEqual(tooltip.indicator, 'line')
    assert.strictEqual(tooltip.label, 'February')
    assert.deepEqual(tooltip.names, ['Desktop'])
    assert.deepEqual(tooltip.entryValues, ['305'])
    assert.strictEqual(chart.cursor, null, 'no cursor')
    assert.strictEqual(chart.activeDots.length, 1, 'a dot at the point')
    await a11yAudit()
  })
})
