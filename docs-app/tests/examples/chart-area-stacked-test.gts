import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartAreaStacked from 'docs-app/examples/chart-area-stacked'

module('Example | chart-area-stacked', function (hooks) {
  setupRenderingTest(hooks)

  test('mobile and desktop stacked, with both in the tooltip', async function (assert) {
    await render(<template><ChartAreaStacked /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Area Chart - Stacked')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(ChartHarness)
    const mobile = chart.seriesFor('mobile')
    const desktop = chart.seriesFor('desktop')
    mobile.points.forEach((point, i) => {
      assert.ok(desktop.points[i]!.y < point.y, `desktop sits on mobile in row ${i}`)
    })
    await chart.hover(1)
    assert.deepEqual(chart.tooltip!.names, ['Desktop', 'Mobile'])
    assert.deepEqual(
      chart.tooltip!.entryValues,
      ['305', '200'],
      'each its own value, not the stack',
    )
    await a11yAudit()
  })
})
