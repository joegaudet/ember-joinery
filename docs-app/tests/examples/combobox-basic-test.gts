import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ComboboxHarness } from '@ember-joinery/test-support'
import ComboboxBasic from 'docs-app/examples/combobox-basic'

module('Example | combobox-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('typing filters the frameworks, and Enter chooses the highlighted one', async function (assert) {
    await render(<template><ComboboxBasic /></template>)
    const combobox = new ComboboxHarness()
    assert.strictEqual(combobox.placeholder, 'Select a framework')
    assert.strictEqual(combobox.label, 'Select a framework')
    assert.false(combobox.isOpen)

    await combobox.open()
    assert.true(combobox.isShown)
    assert.deepEqual(combobox.items, ['Next.js', 'SvelteKit', 'Nuxt.js', 'Remix', 'Astro'])
    await a11yAudit()

    await combobox.type('n')
    assert.deepEqual(combobox.items, ['Next.js', 'Nuxt.js'])
    await combobox.type('u')
    assert.deepEqual(combobox.items, ['Nuxt.js'])
    await combobox.pressKey('ArrowDown')
    assert.strictEqual(combobox.highlighted, 'Nuxt.js')
    await combobox.pressKey('Enter')
    assert.false(combobox.isOpen)
    assert.strictEqual(combobox.inputValue, 'Nuxt.js')

    await combobox.type('zz')
    assert.true(combobox.isEmpty)
    assert.strictEqual(combobox.emptyText, 'No items found.')
    await a11yAudit()
  })
})
