import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { onResize } from '@ember-joinery/primitives/on-resize'
import { waitForObservers } from '@ember-joinery/test-support'

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
    await waitForObservers()
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
    await waitForObservers()
    assert.strictEqual(first.calls, 1)
    assert.strictEqual(second.calls, 1, 'the new callback hears the current size')

    const box = find('#box') as HTMLElement
    box.style.width = '120px'
    await waitForObservers()
    assert.strictEqual(first.calls, 1, 'the old one no longer')
    assert.strictEqual(second.calls, 2)

    state.shown = false
    await settled()
    box.style.width = '200px'
    document.body.append(box) // back in a document, where it could be measured
    await waitForObservers()
    box.remove()
    assert.strictEqual(second.calls, 2, 'nothing after teardown')
    await a11yAudit()
  })
})
