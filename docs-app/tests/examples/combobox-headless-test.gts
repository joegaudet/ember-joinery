import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ComboboxHarness } from '@ember-joinery/test-support'
import ComboboxHeadless from 'docs-app/examples/combobox-headless'

module('Example | combobox-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('the headless combobox filters the fruits as you type', async function (assert) {
    await render(<template><ComboboxHeadless /></template>)
    const combobox = new ComboboxHarness()
    assert.strictEqual(combobox.label, 'Fruit')
    await combobox.type('b')
    assert.deepEqual(combobox.items, ['Banana', 'Blueberry'])
    assert.strictEqual(combobox.highlighted, 'Banana')
    await combobox.pressKey('ArrowDown')
    await combobox.pressKey('Enter')
    assert.strictEqual(combobox.inputValue, 'Blueberry')
    await combobox.type('x')
    assert.strictEqual(combobox.emptyText, 'No fruit matches.')
    await a11yAudit()
  })
})
