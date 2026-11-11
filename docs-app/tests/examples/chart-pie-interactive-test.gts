import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness, SelectHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartPieInteractive from 'docs-app/examples/chart-pie-interactive'

module('Example | chart-pie-interactive', function (hooks) {
  setupRenderingTest(hooks)

  test('the Select picks the month the donut rings and shows in its hole', async function (assert) {
    await render(<template><ChartPieInteractive /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Pie Chart - Interactive')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const select = card.find(SelectHarness)
    assert.strictEqual(select.label, 'Select a value')
    assert.strictEqual(select.valueText, 'January')

    // Looked up each time: the pie is drawn anew when its Label's value changes.
    const visitors = () =>
      Array.from(chart.seriesFor('desktop').element.querySelectorAll('tspan'), t => t.textContent)
    const radius = (sector: SVGPathElement) =>
      Number(/A (\d+(?:\.\d+)?),/.exec(sector.getAttribute('d')!.replace(/\s+/g, ' '))![1])

    // The active month's sector is drawn twice: 10px further out, and a ring 12-25px past it.
    assert.deepEqual(chart.sectorNames('desktop'), [
      'january',
      'january',
      'february',
      'march',
      'april',
      'may',
    ])
    const [active, ring, february] = chart.sectors('desktop')
    assert.strictEqual(radius(active!) - radius(february!), 10, 'the active sector reaches out')
    assert.strictEqual(radius(ring!) - radius(february!), 25, 'and the ring past it')
    assert.deepEqual(visitors(), ['186', 'Visitors'])

    await select.open()
    assert.deepEqual(select.optionTexts, ['January', 'February', 'March', 'April', 'May'])
    await a11yAudit()

    await select.pressOption('march')
    assert.strictEqual(select.valueText, 'March')
    assert.deepEqual(visitors(), ['237', 'Visitors'], 'the hole shows March')
    assert.deepEqual(chart.sectorNames('desktop'), [
      'january',
      'february',
      'march',
      'march',
      'april',
      'may',
    ])

    await chart.hover(1)
    assert.deepEqual(chart.tooltip!.names, ['February'])
    assert.deepEqual(chart.tooltip!.entryValues, ['305'])
    await a11yAudit()
  })
})
