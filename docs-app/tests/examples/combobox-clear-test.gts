import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ComboboxHarness } from '@ember-joinery/test-support'
import ComboboxClear from 'docs-app/examples/combobox-clear'

module('Example | combobox-clear', function (hooks) {
  setupRenderingTest(hooks)

  test('the clear button empties it, and gives the chevron back its place', async function (assert) {
    await render(<template><ComboboxClear /></template>)
    const combobox = new ComboboxHarness()
    assert.strictEqual(combobox.inputValue, 'Next.js')
    assert.dom(combobox.clearButton).hasAttribute('aria-label', 'Clear')
    assert.dom(combobox.trigger).isNotVisible('the chevron hides while there is something to clear')
    await a11yAudit()

    await combobox.clear()
    assert.strictEqual(combobox.inputValue, '')
    assert.strictEqual(combobox.clearButton, null)
    assert.dom(combobox.trigger).isVisible()
    assert.true(combobox.isFocused, 'focus stays in the input')
    await a11yAudit()
  })
})
