import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartAreaIcons from 'docs-app/examples/chart-area-icons'

module('Example | chart-area-icons', function (hooks) {
  setupRenderingTest(hooks)

  test("the legend shows the config's icons", async function (assert) {
    await render(<template><ChartAreaIcons /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Area Chart - Icons')
    assert.strictEqual(card.description, 'Showing total visitors for the last 6 months')
    const chart = card.find(ChartHarness)
    const legend = chart.legend!
    assert.deepEqual(legend.labels, ['Desktop', 'Mobile'])
    assert.true(
      legend.items.every(item => item.swatch === null),
      'an icon for each, in place of the swatch',
    )
    assert.strictEqual(legend.element.querySelectorAll('svg').length, 2)
    await a11yAudit()
  })
})
