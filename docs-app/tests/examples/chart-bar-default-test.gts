import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartBarDefault from 'docs-app/examples/chart-bar-default'

module('Example | chart-bar-default', function (hooks) {
  setupRenderingTest(hooks)

  test('a bar per month, rounded, with a label-less tooltip', async function (assert) {
    await render(<template><ChartBarDefault /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Bar Chart')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    const bars = chart.bars('desktop')
    assert.strictEqual(bars.length, 6)
    assert.dom(bars[0]).hasAttribute('fill', 'var(--color-desktop)')
    assert.true(bars[0]!.getAttribute('d')!.includes('A 8,8'), 'radius 8')
    assert.deepEqual(chart.xTicks, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'])
    assert.deepEqual(chart.gridLines.vertical, [], 'no vertical grid lines')

    await chart.hover(1)
    assert.strictEqual(chart.tooltip!.label, null, 'hideLabel')
    assert.deepEqual(chart.tooltip!.names, ['Desktop'])
    assert.deepEqual(chart.tooltip!.entryValues, ['305'])
    assert.strictEqual(chart.cursor, null, 'no cursor')
    await a11yAudit()
  })
})
