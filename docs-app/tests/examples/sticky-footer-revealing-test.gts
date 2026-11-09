import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { StickyFooterHarness } from '@ember-joinery/test-support'
import StickyFooterRevealing from 'docs-app/examples/sticky-footer-revealing'

class DemoHarness extends StickyFooterHarness {
  async add(times: number): Promise<void> {
    const add = [...this.content.querySelectorAll('button')].find(
      button => button.textContent === 'Add Content',
    )!
    for (let i = 0; i < times; i++) await click(add)
  }

  /** How far the footer's bottom is above the bottom of the wrapper, in CSS pixels. */
  get footerRaised(): number {
    const footer = this.footer.getBoundingClientRect()
    const view = this.element.getBoundingClientRect()
    const scale = view.height / this.element.offsetHeight
    return Math.round((view.bottom - footer.bottom) / scale)
  }
}

module('Example | sticky-footer-revealing', function (hooks) {
  setupRenderingTest(hooks)

  test('the footer sticks above the site-wide one, and rises to its place once scrolled to', async function (assert) {
    await render(<template><StickyFooterRevealing /></template>)
    const layout = new DemoHarness()
    await layout.add(30)
    assert.true(layout.overflows)
    assert.true(layout.isFooterVisible, 'stuck to the bottom while the content scrolls')
    const stuck = layout.footerRaised

    await layout.scrollToEnd()
    assert.true(layout.footerRaised > stuck, 'at the end, it sits higher: in its own place')
    assert.dom(layout.footer).containsText('some information can be hidden until scrolled to.')
    await a11yAudit()
  })
})
