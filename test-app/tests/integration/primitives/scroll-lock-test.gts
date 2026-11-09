import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  REMOVED_SCROLLBAR_SIZE,
  SCROLL_LOCKED,
  isScrollLocked,
  lockScroll,
  scrollLock,
} from '@ember-joinery/primitives/scroll-lock'

/** A wheel turned over an element; returns whether the page cancelled it. */
function wheel(element: Element, deltaY: number, init: { ctrlKey?: boolean } = {}): boolean {
  const event = new WheelEvent('wheel', { deltaY, bubbles: true, cancelable: true, ...init })
  element.dispatchEvent(event)
  return event.defaultPrevented
}

/** A finger dragged over an element from one height to another; whether the move was cancelled. */
function drag(element: Element, fromY: number, toY: number): boolean {
  const touch = (clientY: number) =>
    new Touch({ identifier: 1, target: element, clientX: 10, clientY })
  const start = touch(fromY)
  element.dispatchEvent(
    new TouchEvent('touchstart', {
      bubbles: true,
      cancelable: true,
      touches: [start],
      changedTouches: [start],
    }),
  )
  const end = touch(toY)
  const move = new TouchEvent('touchmove', {
    bubbles: true,
    cancelable: true,
    touches: [end],
    changedTouches: [end],
  })
  element.dispatchEvent(move)
  return move.defaultPrevented
}

module('Integration | primitives | scroll-lock', function (hooks) {
  setupRenderingTest(hooks)

  // A text selection someone left would count as a drag that selects, not a scroll.
  hooks.beforeEach(() => document.getSelection()?.removeAllRanges())

  test('lockScroll takes the scrollbar away and puts everything back', async function (assert) {
    await render(
      <template>
        <p data-test-page>Page</p>
      </template>,
    )
    const body = document.body
    body.style.setProperty('margin-right', '3px')
    const gap = Math.max(0, window.innerWidth - document.documentElement.clientWidth)

    const lock = lockScroll(document)
    assert.true(isScrollLocked())
    assert.dom(body).hasAttribute(SCROLL_LOCKED, '1')
    assert.strictEqual(body.style.getPropertyValue('overflow'), 'hidden')
    assert.strictEqual(body.style.getPropertyPriority('overflow'), 'important')
    assert.strictEqual(
      body.style.getPropertyValue('margin-right'),
      `${3 + gap}px`,
      'the margin makes up for the scrollbar',
    )
    assert.strictEqual(body.style.getPropertyValue(REMOVED_SCROLLBAR_SIZE), `${gap}px`)

    lock.release()
    assert.false(isScrollLocked())
    assert.dom(body).doesNotHaveAttribute(SCROLL_LOCKED)
    assert.strictEqual(body.style.getPropertyValue('overflow'), '')
    assert.strictEqual(body.style.getPropertyValue('margin-right'), '3px', 'its own came back')
    assert.strictEqual(body.style.getPropertyValue(REMOVED_SCROLLBAR_SIZE), '')
    lock.release()
    assert.false(isScrollLocked(), 'releasing twice does nothing')
    body.style.removeProperty('margin-right')
    await a11yAudit()
  })

  test('locks stack, and the page scrolls again when the last ends', async function (assert) {
    await render(
      <template>
        <p>Page</p>
      </template>,
    )
    const first = lockScroll(document)
    const second = lockScroll(document)
    assert.dom(document.body).hasAttribute(SCROLL_LOCKED, '2')
    first.release()
    assert.dom(document.body).hasAttribute(SCROLL_LOCKED, '1')
    assert.strictEqual(document.body.style.getPropertyValue('overflow'), 'hidden')
    second.release()
    assert.dom(document.body).doesNotHaveAttribute(SCROLL_LOCKED)
    await a11yAudit()
  })

  test('a wheel does nothing outside its shards, and scrolls inside them to their ends', async function (assert) {
    await render(
      <template>
        <p data-test-page>Page</p>
        <div data-test-panel style="height: 50px; overflow-y: auto" tabindex="0">
          <div data-test-long style="height: 500px">Long</div>
        </div>
        <div data-test-short style="height: 50px; overflow-y: auto" tabindex="0">Short</div>
      </template>,
    )
    const panel = find('[data-test-panel]')!
    const lock = lockScroll(document, { inside: [panel, find('[data-test-short]')] })

    assert.true(wheel(find('[data-test-page]')!, 100), 'outside: cancelled')
    assert.false(wheel(find('[data-test-long]')!, 100), 'inside, with room below: it scrolls')
    assert.true(wheel(panel, -100), 'at the top, scrolling up: cancelled, so the page stays')
    panel.scrollTop = panel.scrollHeight
    assert.false(wheel(panel, -100), 'with room above: it scrolls')
    assert.true(wheel(panel, 100), 'at the bottom, scrolling down: cancelled')
    assert.true(wheel(find('[data-test-short]')!, 100), 'a shard with nothing to scroll: cancelled')
    assert.false(wheel(find('[data-test-page]')!, 100, { ctrlKey: true }), 'a pinch still zooms')

    lock.update({ inside: [panel], allowPinchZoom: false })
    assert.true(wheel(find('[data-test-page]')!, 100, { ctrlKey: true }), 'unless it may not')

    lock.release()
    assert.false(wheel(find('[data-test-page]')!, 100), 'released: nothing is cancelled')
    await a11yAudit()
  })

  test('a finger does the same', async function (assert) {
    await render(
      <template>
        <p data-test-page>Page</p>
        <div data-test-panel style="height: 50px; overflow-y: auto" tabindex="0">
          <div style="height: 500px">Long</div>
        </div>
      </template>,
    )
    const panel = find('[data-test-panel]')!
    const lock = lockScroll(document, { inside: () => [panel] })
    assert.true(drag(find('[data-test-page]')!, 100, 50), 'outside: cancelled')
    assert.false(drag(panel, 100, 50), 'a drag up scrolls the panel down')
    assert.true(drag(panel, 50, 100), 'at the top, a drag down is cancelled')
    document.getSelection()!.selectAllChildren(panel)
    assert.false(drag(panel, 50, 100), 'but a drag that selects text in it is left alone')
    document.getSelection()!.removeAllRanges()
    lock.release()
    await a11yAudit()
  })

  test('the newest lock decides what scrolls', async function (assert) {
    await render(
      <template>
        <div data-test-a style="height: 50px; overflow-y: auto" tabindex="0"><div
            style="height: 500px"
          ></div></div>
        <div data-test-b style="height: 50px; overflow-y: auto" tabindex="0"><div
            style="height: 500px"
          ></div></div>
      </template>,
    )
    const a = find('[data-test-a]')!
    const b = find('[data-test-b]')!
    const under = lockScroll(document, { inside: [a] })
    const over = lockScroll(document, { inside: [b] })
    assert.true(wheel(a, 100), "the lock underneath's shard doesn't scroll")
    assert.false(wheel(b, 100), "the newest lock's does")
    over.release()
    assert.false(wheel(a, 100), 'once it ends, the one underneath decides again')
    under.release()
    await a11yAudit()
  })

  test('{{scrollLock}} locks while its element is rendered; the element and its shards scroll', async function (assert) {
    class State {
      @tracked shown = true
      @tracked enabled = true
    }
    const state = new State()
    // Read when a wheel turns, so the panel can render after the lock starts.
    const shards = () => [find('[data-test-panel]')]
    await render(
      <template>
        <div data-test-panel style="height: 50px; overflow-y: auto" tabindex="0">
          <div style="height: 500px">Long</div>
        </div>
        {{#if state.shown}}
          <div
            data-test-overlay
            style="height: 50px; overflow-y: auto"
            tabindex="0"
            {{scrollLock inside=shards enabled=state.enabled}}
          ><div style="height: 500px">Long</div></div>
        {{/if}}
      </template>,
    )
    assert.true(isScrollLocked())
    assert.false(wheel(find('[data-test-overlay]')!, 100), 'its own element scrolls')
    assert.false(wheel(find('[data-test-panel]')!, 100), 'and so do its shards')
    assert.true(wheel(document.body, 100))

    state.enabled = false
    await settled()
    assert.false(isScrollLocked(), 'enabled=false lifts it')
    state.enabled = true
    await settled()
    assert.true(isScrollLocked())

    state.shown = false
    await settled()
    assert.false(isScrollLocked(), 'gone with its element')
    await a11yAudit()
  })
})
