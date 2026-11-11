import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartBarActive from 'docs-app/examples/chart-bar-active'

module('Example | chart-bar-active', function (hooks) {
  setupRenderingTest(hooks)

  test('the third bar drawn dashed by the shape', async function (assert) {
    await render(<template><ChartBarActive /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Bar Chart - Active')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const bars = chart.bars('visitors')
    assert.deepEqual(chart.xTicks, ['Chrome', 'Safari', 'Firefox', 'Edge', 'Other'])
    assert
      .dom(bars[2])
      .hasAttribute('fill', 'var(--color-firefox)')
      .hasAttribute('stroke', 'var(--color-firefox)')
      .hasAttribute('stroke-dasharray', '4')
      .hasAttribute('fill-opacity', '0.8')
    assert.dom(bars[0]).doesNotHaveAttribute('stroke-dasharray')
    assert.dom(bars[0]).hasAttribute('stroke-width', '2')

    await chart.hover(2)
    assert.deepEqual(chart.tooltip!.entryValues, ['275'])
    await a11yAudit()
  })
})
