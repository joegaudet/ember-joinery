import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadialText from 'docs-app/examples/chart-radial-text'

module('Example | chart-radial-text', function (hooks) {
  setupRenderingTest(hooks)

  test('a rounded bar, its value in the middle', async function (assert) {
    await render(<template><ChartRadialText /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radial Chart - Text')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(PolarChartHarness)
    assert.deepEqual(chart.polarGrid?.radii, [90, 80])
    const [bar] = chart.radialBars('visitors')
    assert.true(bar!.getAttribute('d')!.includes('A4,4'), 'rounded corners')
    assert.dom(chart.radiusAxis).hasText('200Visitors')
    assert.strictEqual(chart.ring.endAngle, 250)
    await a11yAudit()
  })
})
