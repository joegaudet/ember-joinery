import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadialGrid from 'docs-app/examples/chart-radial-grid'

module('Example | chart-radial-grid', function (hooks) {
  setupRenderingTest(hooks)

  test('bars over round rings', async function (assert) {
    await render(<template><ChartRadialGrid /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radial Chart - Grid')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(PolarChartHarness)
    assert.strictEqual(chart.polarGrid?.type, 'circle')
    assert.strictEqual(chart.polarGrid?.radii.length, 5, "a ring at each band's middle")
    assert.strictEqual(chart.backgroundSectors.length, 0)
    await chart.hover(4)
    assert.deepEqual(chart.tooltip?.names, ['Other'])
    await a11yAudit()
  })
})
