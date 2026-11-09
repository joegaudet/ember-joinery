import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import IncrementalEachDemo from 'docs-app/examples/incremental-each-demo'

/** The text of an element, whitespace collapsed. */
const textOf = (element: Element) => element.textContent!.replace(/\s+/g, ' ').trim()

/**
 * The demo, in a root of the test's own. An `IncrementalEach` renders no element, so its rows
 * are the items of the list around it.
 */
class DemoHarness extends Harness {
  static override component = 'demo'

  /** How many rows are in the document. */
  get rowCount(): number {
    return this.element.querySelectorAll('[aria-label="Rows"] > li').length
  }

  /** What the demo says about the rows: how many, in how many batches, and whether it's done. */
  get status(): string {
    const status = this.element.querySelector('.incremental-count')
    return status ? textOf(status) : ''
  }

  /** The mode the list renders its first batch in, from the button that switches it. */
  get mode(): string {
    return textOf(this.#button('Mode:')).replace('Mode: ', '')
  }

  /** Hides the rows, or shows them again. */
  async toggle(): Promise<void> {
    await click(this.#button('rows'))
  }

  /** Switches the mode; the demo takes a frame to empty the list and start again. */
  async switchMode(): Promise<void> {
    await click(this.#button('Mode:'))
    await new Promise(requestAnimationFrame)
    await settled()
  }

  #button(text: string): HTMLButtonElement {
    const buttons = [...this.element.querySelectorAll('button')]
    const found = buttons.find(button => textOf(button).includes(text))
    if (!found)
      throw new Error(`no button "${text}" (there are: ${buttons.map(textOf).join(', ')})`)
    return found
  }
}

module('Example | incremental-each-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('every one of the 20,000 rows ends up in the document', async function (assert) {
    // The list's test waiter holds `render` until the last batch is in.
    await render(
      <template>
        <div data-test-jn="demo"><IncrementalEachDemo /></div>
      </template>,
    )
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
