import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, StickyFooterHarness, child } from '@ember-joinery/test-support'
import StickyFooterDemo from 'docs-app/examples/sticky-footer-demo'

/**
 * The example: its StickyFooter, and the two buttons in its content. The StickyFooter is a
 * wrapper, so the buttons are the example's parts.
 */
class DemoHarness extends Harness {
  static override component = 'sticky-footer-demo'

  @child(StickyFooterHarness) declare layout: StickyFooterHarness

  async add(times = 1): Promise<void> {
    for (let i = 0; i < times; i++) await click(this.part('add-content'))
  }

  async remove(times = 1): Promise<void> {
    for (let i = 0; i < times; i++) await click(this.part('remove-content'))
  }
}

module('Example | sticky-footer-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('the footer stays at the bottom until the content pushes it down', async function (assert) {
    await render(<template><StickyFooterDemo /></template>)
    const demo = new DemoHarness()
    const { layout } = demo
    assert.dom(layout.footer).hasText('This is the footer')
    assert.true(layout.isFooterAtBottom, 'little content: at the bottom')

    await demo.add(30)
    assert.true(layout.overflows, 'a lot of content')
    assert.false(layout.isFooterVisible, 'the footer is below it')
    await layout.scrollToEnd()
    assert.true(layout.isFooterAtBottom, 'until scrolled to')

    await layout.scrollToTop()
    await demo.remove(30)
    assert.true(layout.isFooterAtBottom, 'back at the bottom')
    await a11yAudit()
  })
})
