import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartLineDefault from 'docs-app/examples/chart-line-default'

module('Example | chart-line-default', function (hooks) {
  setupRenderingTest(hooks)

  test('a natural line without dots', async function (assert) {
    await render(<template><ChartLineDefault /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Line Chart')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const line = chart.seriesFor('desktop')
    assert.strictEqual(line.type, 'line')
    assert.strictEqual(line.stroke, 'var(--color-desktop)')
    assert.true(line.path!.includes('C'), 'a natural curve')
    assert.deepEqual(chart.dots('desktop'), [], 'dot={false}')
    assert.deepEqual(chart.xTicks, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'])
    await chart.hover(4)
    assert.strictEqual(chart.tooltip!.label, null, 'hideLabel')
    assert.deepEqual(chart.tooltip!.entryValues, ['209'])
    await a11yAudit()
  })
})
