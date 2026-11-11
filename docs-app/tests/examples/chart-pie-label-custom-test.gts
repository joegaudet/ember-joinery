import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartPieLabelCustom from 'docs-app/examples/chart-pie-label-custom'

module('Example | chart-pie-label-custom', function (hooks) {
  setupRenderingTest(hooks)

  test('each label drawn by a component, without a line', async function (assert) {
    await render(<template><ChartPieLabelCustom /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Pie Chart - Custom Label')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(ChartHarness)
    assert.deepEqual(chart.labels('visitors'), ['275', '200', '187', '173', '90'])
    assert.strictEqual(chart.labelLines('visitors').length, 0, '@labelLine={{false}}')
    const [label] = chart.surface.querySelectorAll('.recharts-pie-labels text')
    assert.dom(label).hasAttribute('fill', 'var(--foreground)').hasAttribute('text-anchor', 'start')

    await chart.hover(0)
    assert.deepEqual(chart.tooltip!.names, ['Visitors'], 'nameKey="visitors"')
    assert.deepEqual(chart.tooltip!.entryValues, ['275'])
    await a11yAudit()
  })
})
