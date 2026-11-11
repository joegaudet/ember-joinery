import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import ChartRtl from 'docs-app/examples/chart-rtl'

module('Example | chart-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, January is on the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><ChartRtl /></DirectionProvider>
      </template>,
    )
    const chart = new ChartHarness()
    const [january, , , , , june] = chart.categories
    assert.ok(january! > june!, 'the x-axis runs from the right')
    assert.strictEqual(chart.xTicks[0], 'ينا')
    assert.deepEqual(chart.legend!.labels, ['سطح المكتب', 'الجوال'])
    assert.strictEqual(getComputedStyle(chart.legend!.element).direction, 'rtl')
    await chart.hover(0)
    const tooltip = chart.tooltip!
    assert.strictEqual(tooltip.label, 'يناير', 'labelFormatter')
    assert.dom(tooltip.element.querySelector('[data-test-jn-part="label"]')).hasClass('w-32')
    await a11yAudit()
  })
})
