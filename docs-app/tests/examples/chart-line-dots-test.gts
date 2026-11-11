import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartLineDots from 'docs-app/examples/chart-line-dots'

module('Example | chart-line-dots', function (hooks) {
  setupRenderingTest(hooks)

  test('a dot at every point, and a bigger one at the active point', async function (assert) {
    await render(<template><ChartLineDots /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Line Chart - Dots')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const dots = chart.dots('desktop')
    assert.strictEqual(dots.length, 6)
    assert.dom(dots[0]).hasAttribute('fill', 'var(--color-desktop)').hasAttribute('r', '3')
    await chart.hover(1)
    const [active] = chart.activeDots
    assert.dom(active).hasAttribute('r', '6', 'activeDot={{r: 6}}')
    await a11yAudit()
  })
})
