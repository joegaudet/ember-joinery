import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartPieSimple from 'docs-app/examples/chart-pie-simple'

module('Example | chart-pie-simple', function (hooks) {
  setupRenderingTest(hooks)

  test("a sector per browser, in its row's fill", async function (assert) {
    await render(<template><ChartPieSimple /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Pie Chart')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.true(chart.isPie)
    assert.deepEqual(chart.sectorNames('visitors'), [
      'chrome',
      'safari',
      'firefox',
      'edge',
      'other',
    ])
    assert.deepEqual(
      chart.sectors('visitors').map(sector => sector.getAttribute('fill')),
      [
        'var(--color-chrome)',
        'var(--color-safari)',
        'var(--color-firefox)',
        'var(--color-edge)',
        'var(--color-other)',
      ],
    )
    assert.strictEqual(chart.width, chart.height, 'aspect-square')

    await chart.hover(0)
    assert.strictEqual(chart.tooltip!.label, null, 'hideLabel')
    assert.deepEqual(chart.tooltip!.names, ['Chrome'])
    assert.deepEqual(chart.tooltip!.entryValues, ['275'])
    await chart.hover(4)
    assert.deepEqual(chart.tooltip!.names, ['Other'])
    await a11yAudit()
  })
})
