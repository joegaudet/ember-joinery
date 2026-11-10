import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartPieDonutText from 'docs-app/examples/chart-pie-donut-text'

module('Example | chart-pie-donut-text', function (hooks) {
  setupRenderingTest(hooks)

  test("the total visitors in the donut's hole", async function (assert) {
    await render(<template><ChartPieDonutText /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Pie Chart - Donut with Text')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const pie = chart.seriesFor('visitors')
    const [total, caption] = Array.from(pie.element.querySelectorAll('tspan'))
    assert.dom(total).hasText('1,125').hasClass('text-3xl')
    assert.dom(caption).hasText('Visitors')
    assert.strictEqual(Number(total!.getAttribute('x')), chart.width / 2, 'in the middle')
    assert.strictEqual(Number(caption!.getAttribute('y')), chart.height / 2 + 24, 'and below it')

    await chart.hover(2)
    assert.deepEqual(chart.tooltip!.entryValues, ['287'])
    await a11yAudit()
  })
})
