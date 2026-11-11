import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartBarLabel from 'docs-app/examples/chart-bar-label'

module('Example | chart-bar-label', function (hooks) {
  setupRenderingTest(hooks)

  test("each bar's value above it", async function (assert) {
    await render(<template><ChartBarLabel /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Bar Chart - Label')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.deepEqual(chart.labels('desktop'), ['186', '305', '237', '73', '209', '214'])
    const [label] = chart.surface.querySelectorAll('.recharts-label-list text')
    assert.dom(label).hasClass('fill-foreground').hasAttribute('font-size', '12')
    const [bar] = chart.bars('desktop')
    assert.true(
      label!.getBoundingClientRect().bottom <= bar!.getBoundingClientRect().top,
      'above the bar',
    )
    assert.strictEqual(chart.plot.y, 20, 'margin.top makes room for the labels')
    await a11yAudit()
  })
})
