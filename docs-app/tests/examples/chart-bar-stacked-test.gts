import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartBarStacked from 'docs-app/examples/chart-bar-stacked'

module('Example | chart-bar-stacked', function (hooks) {
  setupRenderingTest(hooks)

  test('mobile stacked on desktop, rounded at the ends, with a legend', async function (assert) {
    await render(<template><ChartBarStacked /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Bar Chart - Stacked + Legend')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const [desktop] = chart.bars('desktop')
    const [mobile] = chart.bars('mobile')
    const desktopBox = desktop!.getBoundingClientRect()
    const mobileBox = mobile!.getBoundingClientRect()
    assert.strictEqual(
      Math.round(mobileBox.bottom),
      Math.round(desktopBox.top),
      'mobile sits on top of desktop',
    )
    assert.strictEqual(Math.round(mobileBox.left), Math.round(desktopBox.left), 'in one bar')
    assert.deepEqual(chart.legend!.labels, ['Desktop', 'Mobile'])

    await chart.hover(0)
    assert.deepEqual(chart.tooltip!.entryValues, ['186', '80'])
    assert.notStrictEqual(chart.cursor, null, 'the band under the pointer')
    await a11yAudit()
  })
})
