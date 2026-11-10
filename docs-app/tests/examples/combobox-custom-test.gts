import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ComboboxHarness, ItemHarness } from '@ember-joinery/test-support'
import ComboboxCustom from 'docs-app/examples/combobox-custom'

module('Example | combobox-custom', function (hooks) {
  setupRenderingTest(hooks)

  test('each country is an Item, filtered and chosen by its label', async function (assert) {
    await render(<template><ComboboxCustom /></template>)
    const combobox = new ComboboxHarness()
    assert.strictEqual(combobox.placeholder, 'Search countries...')
    await combobox.open()
    assert.strictEqual(combobox.items.length, 19, 'every country but the placeholder row')
    assert.strictEqual(combobox.items[0], 'Argentina')

    const first = new ItemHarness({ within: combobox.content! })
    assert.strictEqual(first.size, 'xs')
    assert.strictEqual(first.title, 'Argentina')
    assert.strictEqual(first.description, 'South America (ar)')
    await a11yAudit()

    await combobox.type('ken')
    assert.deepEqual(combobox.items, ['Kenya'])
    await combobox.pressKey('ArrowDown')
    await combobox.pressKey('Enter')
    assert.strictEqual(combobox.inputValue, 'Kenya')
    assert.false(combobox.isOpen)

    await combobox.type('zzz')
    assert.true(combobox.isEmpty)
    assert.strictEqual(combobox.emptyText, 'No countries found.')
    await a11yAudit()
  })
})
