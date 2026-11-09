import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ComboboxHarness } from '@ember-joinery/test-support'
import ComboboxMultiple from 'docs-app/examples/combobox-multiple'

module('Example | combobox-multiple', function (hooks) {
  setupRenderingTest(hooks)

  test('frameworks pile up as chips, and come off with their buttons or Backspace', async function (assert) {
    await render(<template><ComboboxMultiple /></template>)
    const combobox = new ComboboxHarness()
    assert.deepEqual(combobox.chips, ['Next.js'], 'it starts with the first')

    await combobox.type('sv')
    assert.deepEqual(combobox.items, ['SvelteKit'])
    assert.strictEqual(combobox.highlighted, 'SvelteKit', 'autoHighlight')
    await combobox.pressKey('Enter')
    assert.deepEqual(combobox.chips, ['Next.js', 'SvelteKit'])
    assert.strictEqual(combobox.inputValue, '', 'the query clears')

    await combobox.open()
    assert.dom(combobox.content).hasAttribute('data-chips', 'true')
    assert.true(combobox.isItemSelected('Next.js'))
    await combobox.pressItem('Astro')
    assert.deepEqual(combobox.chips, ['Next.js', 'SvelteKit', 'Astro'])
    await a11yAudit()

    await combobox.removeChip('SvelteKit')
    assert.deepEqual(combobox.chips, ['Next.js', 'Astro'])
    await combobox.focus()
    await combobox.pressKey('Backspace')
    assert.deepEqual(combobox.chips, ['Next.js'])
    await a11yAudit()
  })
})
