import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartPieLabelList from 'docs-app/examples/chart-pie-label-list'

module('Example | chart-pie-label-list', function (hooks) {
  setupRenderingTest(hooks)

  test("each sector named inside it, by its browser's config label", async function (assert) {
    await render(<template><ChartPieLabelList /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Pie Chart - Label List')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.deepEqual(chart.labels('visitors'), ['Chrome', 'Safari', 'Firefox', 'Edge', 'Other'])
    const [label] = chart.surface.querySelectorAll('.recharts-label-list text')
    assert.dom(label).hasClass('fill-background').hasAttribute('font-size', '12')
    assert.strictEqual(
      getComputedStyle(label!).fill,
      getComputedStyle(card.element).backgroundColor,
      'in the background colour',
    )

    await chart.hover(3)
    assert.deepEqual(chart.tooltip!.names, ['Visitors'])
    assert.deepEqual(chart.tooltip!.entryValues, ['173'])
    await a11yAudit()
  })
})
