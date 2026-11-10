import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DrawerHarness } from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import DrawerDemo from 'docs-app/examples/drawer-demo'

class GoalDrawer extends DrawerHarness {
  button(text: string): ButtonHarness {
    return this.findAll(ButtonHarness).find(button => button.label === text)!
  }

  get goal(): string {
    return this.content!.querySelector('.text-7xl')!.textContent!.trim()
  }
}

module('Example | drawer-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a drawer from the bottom that moves a daily goal over a bar chart', async function (assert) {
    await render(<template><DrawerDemo /></template>)
    const drawer = new GoalDrawer()
    assert.dom(drawer.trigger).hasText('Open Drawer')
    await drawer.open()
    assert.strictEqual(drawer.direction, 'bottom')
    assert.strictEqual(drawer.label, 'Move Goal')
    assert.strictEqual(drawer.descriptionText, 'Set your daily activity goal.')
    drawer.finishAnimations()

    const chart = drawer.find(ChartHarness)
    const [bars] = chart.series
    assert.strictEqual(bars!.type, 'bar')
    assert.strictEqual(bars!.key, 'goal')
    assert.strictEqual(bars!.points.length, 13, 'a bar for each day')
    assert.strictEqual(bars!.fill, 'var(--chart-1)')
    assert.strictEqual(chart.height, 120, 'the chart fills its 120px box')
    await a11yAudit()

    assert.strictEqual(drawer.goal, '350')
    await drawer.button('Decrease').click()
    assert.strictEqual(drawer.goal, '340')
    for (let i = 0; i < 6; i++) await drawer.button('Increase').click()
    assert.strictEqual(drawer.goal, '400')
    assert.true(drawer.button('Increase').isDisabled, 'it goes no higher than 400')
    assert.false(drawer.button('Decrease').isDisabled)

    await drawer.button('Cancel').click()
    assert.false(drawer.isOpen, 'Cancel closes it')
    assert.dom(drawer.trigger).isFocused()
    await a11yAudit()
  })
})
