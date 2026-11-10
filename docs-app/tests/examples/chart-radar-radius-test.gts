import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadarRadius from 'docs-app/examples/chart-radar-radius'

module('Example | chart-radar-radius', function (hooks) {
  setupRenderingTest(hooks)

  test('a radius axis with its values', async function (assert) {
    await render(<template><ChartRadarRadius /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radar Chart - Radius Axis')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(PolarChartHarness)
    assert.deepEqual(chart.radiusTicks, ['0', '80', '160', '240', '320'])
    assert.deepEqual(chart.angleTicks, [], 'no angle axis')
    const [first] = Array.from(chart.radiusAxis!.querySelectorAll('text'))
    assert
      .dom(first)
      .hasAttribute('fill', 'var(--foreground)')
      .hasAttribute('text-anchor', 'middle')
    await chart.hover(1)
    assert.deepEqual(chart.tooltip?.entryValues, ['305', '200'])
    await a11yAudit()
  })
})
