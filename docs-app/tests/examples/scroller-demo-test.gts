import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ScrollerHarness } from '@ember-joinery/test-support'
import ScrollerDemo from 'docs-app/examples/scroller-demo'

/** One of the demo's buttons, by what it says it does. */
function button(label: string): HTMLButtonElement {
  return document.querySelector<HTMLButtonElement>(`button[aria-label="${label}"]`)!
}

module('Example | scroller-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('the four buttons scroll the box to each edge', async function (assert) {
    await render(<template><ScrollerDemo /></template>)
    const scroller = new ScrollerHarness()
    assert.true(scroller.isAtTop && scroller.isAtLeft)

    // The box scrolls smoothly (its CSS); each click waits for the scroll to end.
    await click(button('Scroll to the right'))
    assert.true(scroller.isAtRight && scroller.isAtTop, 'right')
    await click(button('Scroll to the left'))
    assert.true(scroller.isAtLeft, 'left')
    await click(button('Scroll to the bottom'))
    assert.true(scroller.isAtBottom && scroller.isAtLeft, 'down')
    await click(button('Scroll to the right'))
    assert.true(scroller.isAtBottom && scroller.isAtRight, 'and right, staying at the bottom')
    await click(button('Scroll to the top'))
    assert.true(scroller.isAtTop && scroller.isAtRight, 'up')
    await a11yAudit()
  })
})
