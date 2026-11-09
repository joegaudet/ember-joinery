import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, StickyFooterHarness, child } from '@ember-joinery/test-support'
import StickyFooterRevealing from 'docs-app/examples/sticky-footer-revealing'

/**
 * The example: its StickyFooter, and the button in its content that adds paragraphs. The
 * StickyFooter is a wrapper, so the button is the example's part.
 */
class RevealingDemoHarness extends Harness {
  static override component = 'sticky-footer-revealing'

  @child(StickyFooterHarness) declare layout: StickyFooterHarness

  async add(times = 1): Promise<void> {
    for (let i = 0; i < times; i++) await click(this.part('add-content'))
  }

  /** How far the footer's bottom is above the bottom of the layout's view, in CSS pixels. */
  get footerRaised(): number {
    const { element, footer } = this.layout
    const box = footer.getBoundingClientRect()
    const view = element.getBoundingClientRect()
    const scale = view.height / element.offsetHeight
    return Math.round((view.bottom - box.bottom) / scale)
  }
}

module('Example | sticky-footer-revealing', function (hooks) {
  setupRenderingTest(hooks)

  test('the footer sticks above the site-wide one, and rises to its place once scrolled to', async function (assert) {
    await render(<template><StickyFooterRevealing /></template>)
    const demo = new RevealingDemoHarness()
    const { layout } = demo
    await demo.add(30)
    assert.true(layout.overflows)
    assert.true(layout.isFooterVisible, 'stuck to the bottom while the content scrolls')
    const stuck = demo.footerRaised

    await layout.scrollToEnd()
    assert.true(demo.footerRaised > stuck, 'at the end, it sits higher: in its own place')
    assert.dom(layout.footer).containsText('some information can be hidden until scrolled to.')
    await a11yAudit()
  })
})
