import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartBarMixed from 'docs-app/examples/chart-bar-mixed'

module('Example | chart-bar-mixed', function (hooks) {
  setupRenderingTest(hooks)

  test("each browser's bar in its own colour, named by the config", async function (assert) {
    await render(<template><ChartBarMixed /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Bar Chart - Mixed')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.deepEqual(chart.yTicks, ['Chrome', 'Safari', 'Firefox', 'Edge', 'Other'])
    assert.deepEqual(
      chart.bars('visitors').map(bar => bar.getAttribute('fill')),
      [
        'var(--color-chrome)',
        'var(--color-safari)',
        'var(--color-firefox)',
        'var(--color-edge)',
        'var(--color-other)',
      ],
      "each row's fill",
    )

    await chart.hover(1)
    assert.deepEqual(chart.tooltip!.names, ['Visitors'])
    assert.deepEqual(chart.tooltip!.entryValues, ['200'])
    assert.true(
      chart.tooltip!.items[0]!.indicator!.getAttribute('style')!.includes('var(--color-safari)'),
    )
    await a11yAudit()
  })
})
