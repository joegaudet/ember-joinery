import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartLineLabel from 'docs-app/examples/chart-line-label'

module('Example | chart-line-label', function (hooks) {
  setupRenderingTest(hooks)

  test('each point labelled with its value', async function (assert) {
    await render(<template><ChartLineLabel /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Line Chart - Label')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.deepEqual(chart.labels('desktop'), ['186', '305', '237', '73', '209', '214'])
    const [label] = chart.surface.querySelectorAll('.recharts-label-list text')
    assert.dom(label).hasClass('fill-foreground').hasAttribute('font-size', '12')
    const [point] = chart.seriesFor('desktop').points
    assert.true(
      Math.abs(Number(label!.getAttribute('y')) - (point!.y - 12)) < 0.01,
      'offset={12} above the point',
    )
    await a11yAudit()
  })
})
