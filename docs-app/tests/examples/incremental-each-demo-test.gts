import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, getRootElement, render, settled } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import IncrementalEachDemo from 'docs-app/examples/incremental-each-demo'

/** The demo's buttons, by their text. */
function button(text: string): HTMLButtonElement {
  const buttons = [...getRootElement().querySelectorAll('.incremental-controls button')]
  const label = (b: Element) => b.textContent!.replace(/\s+/g, ' ').trim()
  const found = buttons.find(b => label(b).includes(text))
  if (!found) {
    const shown = buttons.map(label).join(', ')
    throw new Error(`no button "${text}" (there are: ${shown})`)
  }
  return found as HTMLButtonElement
}

/** How many rows are in the document. */
const rowCount = () => getRootElement().querySelectorAll('.incremental-demo li').length

module('Example | incremental-each-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('every one of the 20,000 rows ends up in the document', async function (assert) {
    // The list's test waiter holds `render` until the last batch is in.
    await render(<template><IncrementalEachDemo /></template>)
    assert.strictEqual(rowCount(), 20_000)
    assert.dom('.incremental-count').containsText('20000 rows · 50 batches', 'and it’s done')
    assert.dom('.incremental-count').containsText('(done)')

    await click(button('Hide'))
    assert.strictEqual(rowCount(), 0, 'hidden')
    await click(button('Show'))
    assert.strictEqual(rowCount(), 20_000, 'shown again, in full')

    await click(button('Mode: lazy'))
    await new Promise(requestAnimationFrame)
    await settled()
    assert.dom(button('Mode: sync')).exists('the mode switched')
    assert.strictEqual(rowCount(), 20_000)
    await a11yAudit()
  })
})
