import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartAreaGradient from 'docs-app/examples/chart-area-gradient'

module('Example | chart-area-gradient', function (hooks) {
  setupRenderingTest(hooks)

  test('areas filled with the gradients the block defines', async function (assert) {
    await render(<template><ChartAreaGradient /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Area Chart - Gradient')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(ChartHarness)
    assert.strictEqual(chart.seriesFor('desktop').fill, 'url(#fillDesktop)')
    assert.strictEqual(chart.seriesFor('mobile').fill, 'url(#fillMobile)')
    assert.dom(chart.surface.querySelector('#fillDesktop')).exists('the gradient is in the chart')
    await chart.hover(2)
    assert.deepEqual(chart.tooltip!.names, ['Desktop', 'Mobile'])
    await a11yAudit()
  })
})
