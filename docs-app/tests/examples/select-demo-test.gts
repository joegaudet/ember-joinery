import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SelectHarness } from '@ember-joinery/test-support'
import SelectDemo from 'docs-app/examples/select-demo'

module('Example | select-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a fruit is chosen from the Fruits group', async function (assert) {
    await render(<template><SelectDemo /></template>)
    const select = new SelectHarness()
    assert.strictEqual(select.valueText, 'Select a fruit')
    assert.true(select.isPlaceholder)
    assert.strictEqual(select.label, 'Fruit')

    await select.open()
    assert.true(select.isShown)
    assert.strictEqual(select.position, 'item-aligned')
    assert.deepEqual(select.groups, ['Fruits'])
    assert.deepEqual(select.optionTexts, ['Apple', 'Banana', 'Blueberry', 'Grapes', 'Pineapple'])
    assert.dom(select.option('apple')).isFocused('the first option, with nothing chosen')
    await a11yAudit()

    await select.pressOption('blueberry')
    assert.false(select.isOpen)
    assert.strictEqual(select.value, 'blueberry')
    assert.strictEqual(select.valueText, 'Blueberry')
    assert.true(select.isFocused)
    await a11yAudit()
  })
})
