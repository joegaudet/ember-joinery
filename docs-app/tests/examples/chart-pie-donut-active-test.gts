import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartPieDonutActive from 'docs-app/examples/chart-pie-donut-active'

module('Example | chart-pie-donut-active', function (hooks) {
  setupRenderingTest(hooks)

  test('the first sector drawn 10px further out by the shape', async function (assert) {
    await render(<template><ChartPieDonutActive /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Pie Chart - Donut Active')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const [chrome, safari] = chart
      .sectors('visitors')
      .map(sector => sector.getAttribute('d')!.replace(/\s+/g, ' '))
    const radius = (d: string) => Number(/A (\d+(?:\.\d+)?),/.exec(d)![1])
    assert.strictEqual(radius(chrome!) - radius(safari!), 10)
    assert.dom(chart.sectors('visitors')[0]).hasAttribute('stroke-width', '5')

    await chart.hover(0)
    assert.deepEqual(chart.tooltip!.names, ['Chrome'])
    await a11yAudit()
  })
})
