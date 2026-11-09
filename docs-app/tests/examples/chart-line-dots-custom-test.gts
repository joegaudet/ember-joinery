import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartLineDotsCustom from 'docs-app/examples/chart-line-dots-custom'

module('Example | chart-line-dots-custom', function (hooks) {
  setupRenderingTest(hooks)

  test('each point drawn as an icon', async function (assert) {
    await render(<template><ChartLineDotsCustom /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Line Chart - Custom Dots')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const dots = chart.dots('desktop')
    assert.strictEqual(dots.length, 6)
    const [first] = dots
    const [point] = chart.seriesFor('desktop').points
    assert.dom(first).hasAttribute('width', '24').hasAttribute('stroke', 'var(--color-desktop)')
    assert.true(
      Math.abs(Number(first!.getAttribute('x')) - (point!.x - 12)) < 0.01,
      'centred on the point',
    )
    await a11yAudit()
  })
})
