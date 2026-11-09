import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { isScrollLocked } from '@ember-joinery/primitives/scroll-lock'
import { Harness } from '@ember-joinery/test-support'
import ScrollLockPanel from 'docs-app/examples/scroll-lock-panel'

class ScrollLockPanelHarness extends Harness {
  static override component = 'scroll-lock-panel'

  get panel() {
    return this.queryPart('panel')
  }

  async toggle() {
    await click(this.part('toggle'))
  }
}

/** A wheel turned over an element; whether the page cancelled it. */
function wheel(element: Element, deltaY: number): boolean {
  const event = new WheelEvent('wheel', { deltaY, bubbles: true, cancelable: true })
  element.dispatchEvent(event)
  return event.defaultPrevented
}

module('Example | scroll-lock-panel', function (hooks) {
  setupRenderingTest(hooks)

  test('the page stays put while the panel scrolls', async function (assert) {
    await render(<template><ScrollLockPanel /></template>)
    const example = new ScrollLockPanelHarness()
    await example.toggle()

    assert.true(isScrollLocked())
    assert.dom(document.body).hasAttribute('data-scroll-locked')
    assert.true(wheel(example.part('toggle'), 100), 'outside the panel, nothing scrolls')
    assert.false(wheel(example.panel!, 100), 'the panel scrolls')
    assert.true(wheel(example.panel!, -100), 'but not past its top')
    await a11yAudit()

    await example.toggle()
    assert.false(isScrollLocked(), 'the page scrolls again')
    await a11yAudit()
  })
})
