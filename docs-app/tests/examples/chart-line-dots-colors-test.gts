import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartLineDotsColors from 'docs-app/examples/chart-line-dots-colors'

module('Example | chart-line-dots-colors', function (hooks) {
  setupRenderingTest(hooks)

  test("each dot in its browser's colour", async function (assert) {
    await render(<template><ChartLineDotsColors /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Line Chart - Dots Colors')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const dots = chart.dots('visitors')
    assert.deepEqual(
      dots.map(dot => dot.getAttribute('fill')),
      [
        'var(--color-chrome)',
        'var(--color-safari)',
        'var(--color-firefox)',
        'var(--color-edge)',
        'var(--color-other)',
      ],
    )
    assert.dom(dots[0]).hasAttribute('r', '5').hasClass('recharts-dot')
    await chart.hover(1)
    assert.deepEqual(chart.tooltip!.names, ['Visitors'])
    assert.deepEqual(chart.tooltip!.entryValues, ['200'])
    await a11yAudit()
  })
})
