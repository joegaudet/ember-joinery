import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ButtonHarness, DrawerHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import DrawerRtl from 'docs-app/examples/drawer-rtl'

class GoalDrawer extends DrawerHarness {
  button(text: string): ButtonHarness {
    return this.findAll(ButtonHarness).find(button => button.label === text)!
  }

  get goal(): string {
    return this.content!.querySelector('.text-7xl')!.textContent!.trim()
  }
}

module('Example | drawer-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, in Arabic, the goal and the chart run from the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><DrawerRtl /></DirectionProvider>
      </template>,
    )
    const drawer = new GoalDrawer()
    assert.dom(drawer.trigger).hasText('فتح الدرج')
    await drawer.open()
    assert.strictEqual(drawer.label, 'نقل الهدف')
    assert.strictEqual(drawer.descriptionText, 'حدد هدف نشاطك اليومي.')
    drawer.finishAnimations()
    assert.strictEqual(getComputedStyle(drawer.content!).direction, 'rtl')

    const chart = drawer.find(ChartHarness)
    const [bars] = chart.series
    assert.strictEqual(bars!.points.length, 13)
    assert.strictEqual(bars!.fill, 'var(--chart-2)')
    const first = bars!.points[0]!
    const last = bars!.points[12]!
    assert.ok(first.x > last.x, 'the x-axis runs from the right')
    assert.ok(chart.xTicks.length > 0)
    assert.ok(
      chart.xTicks.every(tick => /^[٠-٩٬]+$/.test(tick)),
      `the ticks are in Arabic digits (${chart.xTicks.join(' ')})`,
    )
    await a11yAudit()

    assert.strictEqual(drawer.goal, '٣٥٠')
    await drawer.button('زيادة').click()
    assert.strictEqual(drawer.goal, '٣٦٠')
    await drawer.button('تقليل').click()
    await drawer.button('تقليل').click()
    assert.strictEqual(drawer.goal, '٣٤٠')

    await drawer.button('إلغاء').click()
    assert.false(drawer.isOpen)
    assert.dom(drawer.trigger).isFocused()
    await a11yAudit()
  })
})
