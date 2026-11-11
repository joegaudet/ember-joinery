import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'
import ChartRadialLabel from 'docs-app/examples/chart-radial-label'

module('Example | chart-radial-label', function (hooks) {
  setupRenderingTest(hooks)

  test('each bar labelled along its start', async function (assert) {
    await render(<template><ChartRadialLabel /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radial Chart - Label')
    assert.strictEqual(card.description, 'January - June 2024')
    const chart = card.find(PolarChartHarness)
    assert.deepEqual(chart.labels('visitors'), ['chrome', 'safari', 'firefox', 'edge', 'other'])
    const [label] = Array.from(chart.surface.querySelectorAll('[data-test-jn-part="label"]'))
    assert.dom(label).hasClass('capitalize').hasAttribute('font-size', '11')
    assert.dom(label!.querySelector('textPath')).exists('along an arc')
    assert.strictEqual(chart.ring.startAngle, -90)
    assert.strictEqual(chart.ring.endAngle, 380)
    await a11yAudit()
  })
})
