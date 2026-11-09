import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ignoreROError, onResize, resizeObserver } from '@ember-joinery/primitives/on-resize'

/** Two frames: by then the browser has delivered the resize a change caused. */
async function nextFrames() {
  await settled()
  await new Promise(requestAnimationFrame)
  await new Promise(requestAnimationFrame)
  await settled()
}

class Sizes {
  @tracked last = ''
  calls = 0
  record = (entry: ResizeObserverEntry) => {
    this.calls += 1
    const { width, height } = entry.contentRect
    this.last = `${width} × ${height}`
  }
}

module('Integration | primitives | on-resize', function (hooks) {
  setupRenderingTest(hooks)

  test('calls back at the start and on each resize', async function (assert) {
    const sizes = new Sizes()
    await render(
      <template>
        <div id="box" style="width: 100px; height: 50px;" {{onResize sizes.record}}>Resize me</div>
        <output>{{sizes.last}}</output>
      </template>,
    )
    assert.dom('output').hasText('100 × 50', 'at the start (the first report is waited for)')
    assert.strictEqual(sizes.calls, 1)

    const box = find('#box') as HTMLElement
    box.style.width = '150px'
    await nextFrames()
    assert.dom('output').hasText('150 × 50')
    assert.strictEqual(sizes.calls, 2)
    await a11yAudit()
  })

  test('a new callback replaces the old one, and teardown stops it', async function (assert) {
    class State {
      @tracked shown = true
      @tracked callback: (entry: ResizeObserverEntry) => void
      constructor(callback: (entry: ResizeObserverEntry) => void) {
        this.callback = callback
      }
    }
    const first = new Sizes()
    const second = new Sizes()
    const state = new State(first.record)
    await render(
      <template>
        {{#if state.shown}}
          <div id="box" style="width: 100px; height: 50px;" {{onResize state.callback}}>Box</div>
        {{/if}}
      </template>,
    )
    state.callback = second.record
    await nextFrames()
    assert.strictEqual(first.calls, 1)
    assert.strictEqual(second.calls, 1, 'the new callback hears the current size')

    const box = find('#box') as HTMLElement
    box.style.width = '120px'
    await nextFrames()
    assert.strictEqual(first.calls, 1, 'the old one no longer')
    assert.strictEqual(second.calls, 2)

    state.shown = false
    await settled()
    box.style.width = '200px'
    document.body.append(box) // back in a document, where it could be measured
    await nextFrames()
    box.remove()
    assert.strictEqual(second.calls, 2, 'nothing after teardown')
    await a11yAudit()
  })

  test('tests settle even when the browser has nothing to report', async function (assert) {
    const sizes = new Sizes()
    const detached = document.createElement('div')
    resizeObserver(this.owner).observe(detached, sizes.record)
    await settled() // waits two frames at most for a first report
    assert.true(sizes.calls <= 1, 'settled, with at most the 0 × 0 report')
    resizeObserver(this.owner).unobserve(detached, sizes.record)
    await a11yAudit()
  })

  test('resizeObserver() shares one per owner', async function (assert) {
    const observer = resizeObserver(this.owner)
    assert.strictEqual(resizeObserver(this), observer)
    await render(
      <template>
        <div id="box" style="width: 30px; height: 20px;">Box</div>
      </template>,
    )
    const sizes = new Sizes()
    observer.observe(find('#box')!, sizes.record)
    await settled()
    assert.strictEqual(sizes.last, '30 × 20')
    observer.unobserve(find('#box')!, sizes.record)
    await a11yAudit()
  })

  test("ignores the browser's resize loop message", async function (assert) {
    const seen: unknown[] = []
    const original = window.onerror
    window.onerror = (message: unknown) => {
      seen.push(message)
      return true
    }
    try {
      ignoreROError()
      ignoreROError() // wraps once
      const handler = window.onerror as NonNullable<typeof window.onerror>
      assert.true(handler('ResizeObserver loop limit exceeded'), 'the loop message is handled')
      handler('ResizeObserver loop completed with undelivered notifications.')
      handler('A real error')
      assert.deepEqual(seen, ['A real error'], 'other errors still reach the handler')
    } finally {
      window.onerror = original
    }
    await a11yAudit()
  })
})
