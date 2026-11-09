import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { focus, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { RovingFocusGroupHarness, pressKey, tab, typeKeys } from '@ember-joinery/test-support'
import TypeaheadListbox from 'docs-app/examples/typeahead-listbox'

/** The listbox: a vertical roving focus group of options, with typeahead. */
class FruitListbox extends RovingFocusGroupHarness {
  static named = 'fruit'

  /** The chosen fruit, read from aria-selected. */
  get selected() {
    const option = this.items.find(item => item.getAttribute('aria-selected') === 'true')
    return option?.textContent?.trim() ?? null
  }

  /** Types the start of a fruit's name, as a user does in a listbox. */
  async type(text: string) {
    await typeKeys(text)
  }
}

module('Example | typeahead-listbox', function (hooks) {
  setupRenderingTest(hooks)

  test('typing moves to the fruit that starts with it', async function (assert) {
    await render(
      <template>
        <button type="button" id="before">Before</button>
        <TypeaheadListbox />
      </template>,
    )
    const listbox = new FruitListbox()
    assert.strictEqual(listbox.selected, 'Banana')

    await focus('#before')
    await tab()
    assert.strictEqual(listbox.focused, 'Banana', 'Tab enters on the chosen fruit')

    await listbox.type('bl')
    assert.strictEqual(listbox.focused, 'Blackberry', '"bl"')
    await listbox.type('u')
    assert.strictEqual(listbox.focused, 'Blueberry', '"blu"')

    await pressKey(' ')
    assert.strictEqual(listbox.selected, 'Banana', 'Space during a search chooses nothing')
    await a11yAudit()
  })

  test('the arrows still move, and Enter chooses', async function (assert) {
    await render(<template><TypeaheadListbox /></template>)
    const listbox = new FruitListbox()
    await listbox.focus('Cherry')
    await listbox.press('ArrowDown')
    assert.strictEqual(listbox.focused, 'Grape')
    await listbox.press('Enter')
    assert.strictEqual(listbox.selected, 'Grape')

    await listbox.type('a')
    assert.strictEqual(listbox.focused, 'Apple', 'typing wraps round to the top')
    await listbox.type('a')
    assert.strictEqual(listbox.focused, 'Apricot', 'the same letter again moves on')
    await a11yAudit()
  })
})
