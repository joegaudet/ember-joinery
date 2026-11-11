import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import IncrementalEachDemo from 'docs-app/examples/incremental-each-demo'

/** The text of an element, whitespace collapsed. */
const textOf = (element: Element) => element.textContent!.replace(/\s+/g, ' ').trim()

/** The demo: its two buttons, what it says about the rows, and the list they render in. */
class DemoHarness extends Harness {
  static override component = 'incremental-each-demo'

  /** How many rows are in the document: an `IncrementalEach` renders no element of its own. */
  get rowCount(): number {
    return this.queryPart('rows')?.children.length ?? 0
  }

  /** What the demo says about the rows: how many, in how many batches, and whether it's done. */
  get status(): string {
    const status = this.queryPart('status')
    return status ? textOf(status) : ''
  }

  /** The mode the list renders its first batch in, from the button that switches it. */
  get mode(): string {
    return textOf(this.part('mode')).replace('Mode: ', '')
  }

  /** Hides the rows, or shows them again. */
  async toggle(): Promise<void> {
    await click(this.part('toggle'))
  }

  /** Switches the mode; the demo takes a frame to empty the list and start again. */
  async switchMode(): Promise<void> {
    await click(this.part('mode'))
    await new Promise(requestAnimationFrame)
    await settled()
  }
}

module('Example | incremental-each-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('every one of the 20,000 rows ends up in the document', async function (assert) {
    // The list's test waiter holds `render` until the last batch is in.
    await render(<template><IncrementalEachDemo /></template>)
    const demo = new DemoHarness()
    assert.strictEqual(demo.rowCount, 20_000)
    assert.true(demo.status.includes('20000 rows · 50 batches'), demo.status)
    assert.true(demo.status.endsWith('(done)'), 'and it’s done')

    await demo.toggle()
    assert.strictEqual(demo.rowCount, 0, 'hidden')
    await demo.toggle()
    assert.strictEqual(demo.rowCount, 20_000, 'shown again, in full')

    assert.strictEqual(demo.mode, 'lazy')
    await demo.switchMode()
    assert.strictEqual(demo.mode, 'sync', 'the mode switched')
    assert.strictEqual(demo.rowCount, 20_000)
    await a11yAudit()
  })
})
