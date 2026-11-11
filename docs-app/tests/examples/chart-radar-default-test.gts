import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarDefault from 'docs-app/examples/chart-radar-default'

module('Example | chart-radar-default', function (hooks) {
  setupRenderingTest(hooks)

  test('a radar of desktop visitors, round the months', async function (assert) {
    await render(<template><ChartRadarDefault /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    assert.strictEqual(chart.layout, 'centric')
    assert.deepEqual(chart.angleTicks, ['January', 'February', 'March', 'April', 'May', 'June'])
    assert.strictEqual(chart.polarGrid?.type, 'polygon')
    assert.strictEqual(chart.polarGrid?.radii.length, 5, 'a ring at each of the radius axis ticks')
    assert
      .dom(chart.polygon('desktop'))
      .hasAttribute('fill', 'var(--color-desktop)')
      .hasAttribute('fill-opacity', '0.6')
    assert.deepEqual(chart.dots('desktop'), [], 'no dots')
    await chart.hover(1)
    assert.strictEqual(chart.tooltip?.label, 'February')
    assert.deepEqual(chart.tooltip?.names, ['Desktop'])
    assert.deepEqual(chart.tooltip?.entryValues, ['305'])
    assert.strictEqual(chart.cursor, null, 'cursor={false}')
    await a11yAudit()
  })
})
