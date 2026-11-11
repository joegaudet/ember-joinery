import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartPieDonut from 'docs-app/examples/chart-pie-donut'

module('Example | chart-pie-donut', function (hooks) {
  setupRenderingTest(hooks)

  test('a donut: each sector a ring', async function (assert) {
    await render(<template><ChartPieDonut /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Pie Chart - Donut')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const [chrome] = chart.sectors('visitors')
    const d = chrome!.getAttribute('d')!.replace(/\s+/g, ' ')
    assert.true(d.includes('A 60,60'), 'an inner radius of 60')

    await chart.hover(0)
    assert.deepEqual(chart.tooltip!.names, ['Chrome'])
    await a11yAudit()
  })
})
