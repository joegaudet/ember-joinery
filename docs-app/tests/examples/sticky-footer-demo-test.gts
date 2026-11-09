import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { StickyFooterHarness } from '@ember-joinery/test-support'
import StickyFooterDemo from 'docs-app/examples/sticky-footer-demo'

/** The StickyFooter in the example, with its two buttons. */
class DemoHarness extends StickyFooterHarness {
  #button(text: string): HTMLButtonElement {
    return [...this.content.querySelectorAll('button')].find(b => b.textContent === text)!
  }

  async add(times = 1): Promise<void> {
    for (let i = 0; i < times; i++) await click(this.#button('Add Content'))
  }

  async remove(times = 1): Promise<void> {
    for (let i = 0; i < times; i++) await click(this.#button('Remove Content'))
  }
}

module('Example | sticky-footer-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('the footer stays at the bottom until the content pushes it down', async function (assert) {
    await render(<template><StickyFooterDemo /></template>)
    const layout = new DemoHarness()
    assert.dom(layout.footer).hasText('This is the footer')
    assert.true(layout.isFooterAtBottom, 'little content: at the bottom')

    await layout.add(30)
    assert.true(layout.overflows, 'a lot of content')
    assert.false(layout.isFooterVisible, 'the footer is below it')
    await layout.scrollToEnd()
    assert.true(layout.isFooterAtBottom, 'until scrolled to')

    await layout.scrollToTop()
    await layout.remove(30)
    assert.true(layout.isFooterAtBottom, 'back at the bottom')
    await a11yAudit()
  })
})
