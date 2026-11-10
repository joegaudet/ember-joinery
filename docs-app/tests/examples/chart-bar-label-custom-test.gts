import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartBarLabelCustom from 'docs-app/examples/chart-bar-label-custom'

module('Example | chart-bar-label-custom', function (hooks) {
  setupRenderingTest(hooks)

  test('each month inside its bar and its value past the end', async function (assert) {
    await render(<template><ChartBarLabelCustom /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Bar Chart - Custom Label')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const [months, values] = chart.labelLists('desktop')
    assert.deepEqual(months, ['January', 'February', 'March', 'April', 'May', 'June'])
    assert.deepEqual(values, ['186', '305', '237', '73', '209', '214'])
    assert.deepEqual(chart.yTicks, [], 'the y-axis is hidden')
    assert.deepEqual(chart.gridLines.horizontal, [], 'no horizontal grid lines')
    const texts = chart.surface.querySelectorAll('.recharts-label-list text')
    assert.dom(texts[0]).hasClass('fill-(--color-label)').hasAttribute('text-anchor', 'start')
    assert.strictEqual(
      getComputedStyle(texts[0]!).fill,
      getComputedStyle(card.element).backgroundColor,
      "the month in the background colour (the config's --color-label)",
    )

    await chart.hover(0)
    assert.strictEqual(chart.tooltip!.indicator, 'line')
    assert.strictEqual(chart.tooltip!.label, 'January')
    await a11yAudit()
  })
})
