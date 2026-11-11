import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ignoreROError, resizeObserver } from '@ember-joinery/primitives/resize-observer'
import { waitForObservers } from '@ember-joinery/test-support'
import { BoxHarness } from 'test-app/tests/fixtures/primitives/box'

class Sizes {
  @tracked last = ''
  calls = 0
  record = (entry: ResizeObserverEntry) => {
    this.calls += 1
    const { width, height } = entry.contentRect
    this.last = `${width} × ${height}`
  }
}

module('Integration | primitives | resize-observer', function (hooks) {
  setupRenderingTest(hooks)

  test('a second callback on the same element hears the current size, and only it does', async function (assert) {
    await render(
      <template>
        <div data-test-jn="box" style="width: 100px; height: 50px;">Box</div>
      </template>,
    )
    const harness = new BoxHarness()
    const box = harness.element
    const observer = resizeObserver(this.owner)
    const first = new Sizes()
    const second = new Sizes()
    observer.observe(box, first.record)
    await settled()
    assert.strictEqual(first.calls, 1)

    observer.observe(box, second.record)
    await waitForObservers()
    assert.strictEqual(second.calls, 1, 'the new callback gets where the element is now')
    assert.strictEqual(second.last, '100 × 50')
    assert.strictEqual(first.calls, 1, 'the first hears nothing new')

    observer.observe(box, second.record)
    await waitForObservers()
    assert.strictEqual(second.calls, 1, 'observing again with the same callback changes nothing')

    await harness.resizeTo(140)
    assert.deepEqual([first.calls, second.calls], [2, 2], 'both hear a resize, once each')

    observer.unobserve(box, first.record)
    await harness.resizeTo(160)
    assert.deepEqual([first.calls, second.calls], [2, 3], 'the other still listens')
    observer.unobserve(box, second.record)
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
        <div data-test-jn="box" style="width: 30px; height: 20px;">Box</div>
      </template>,
    )
    const sizes = new Sizes()
    const box = new BoxHarness().element
    observer.observe(box, sizes.record)
    await settled()
    assert.strictEqual(sizes.last, '30 × 20')
    observer.unobserve(box, sizes.record)
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
