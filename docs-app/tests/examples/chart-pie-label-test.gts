import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartPieLabel from 'docs-app/examples/chart-pie-label'

module('Example | chart-pie-label', function (hooks) {
  setupRenderingTest(hooks)

  test("each sector's value outside it, with a line to it", async function (assert) {
    await render(<template><ChartPieLabel /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Pie Chart - Label')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.deepEqual(chart.labels('visitors'), ['275', '200', '187', '173', '90'])
    const lines = chart.labelLines('visitors')
    assert.strictEqual(lines.length, 5)
    assert.dom(lines[0]).hasAttribute('stroke', 'var(--color-chrome)')
    const [label] = chart.surface.querySelectorAll('.recharts-pie-label-text')
    assert.strictEqual(
      getComputedStyle(label!).fill,
      getComputedStyle(card.element).color,
      "the container's class turns the labels the foreground colour",
    )

    await chart.hover(2)
    assert.deepEqual(chart.tooltip!.names, ['Firefox'])
    await a11yAudit()
  })
})
