import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartPieSeparatorNone from 'docs-app/examples/chart-pie-separator-none'

module('Example | chart-pie-separator-none', function (hooks) {
  setupRenderingTest(hooks)

  test('the sectors with no line between them', async function (assert) {
    await render(<template><ChartPieSeparatorNone /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Pie Chart - Separator None')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const sectors = chart.sectors('visitors')
    assert.strictEqual(sectors.length, 5)
    for (const sector of sectors) assert.dom(sector).hasAttribute('stroke', '0')

    await chart.hover(1)
    assert.deepEqual(chart.tooltip!.names, ['Safari'])
    await a11yAudit()
  })
})
