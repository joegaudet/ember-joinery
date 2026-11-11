import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartBarNegative from 'docs-app/examples/chart-bar-negative'

module('Example | chart-bar-negative', function (hooks) {
  setupRenderingTest(hooks)

  test('negative months below the line, each Cell coloured by its sign', async function (assert) {
    await render(<template><ChartBarNegative /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Bar Chart - Negative')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const bars = chart.bars('visitors')
    assert.deepEqual(
      bars.map(bar => bar.getAttribute('fill')),
      [
        'var(--chart-1)',
        'var(--chart-1)',
        'var(--chart-2)',
        'var(--chart-1)',
        'var(--chart-2)',
        'var(--chart-1)',
      ],
    )
    assert.deepEqual(chart.labels('visitors'), [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
    ])
    const march = bars[2]!.getBoundingClientRect()
    const april = bars[3]!.getBoundingClientRect()
    assert.true(march.top >= april.bottom - 1, "March's bar hangs below the zero line")

    await chart.hover(4)
    assert.deepEqual(chart.tooltip!.entryValues, ['-209'])
    assert.strictEqual(chart.tooltip!.items[0]!.indicator, null, 'hideIndicator')
    await a11yAudit()
  })
})
