import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, SelectHarness, SwitchHarness } from '@ember-joinery/test-support'
import SelectAlignItem from 'docs-app/examples/select-align-item'

module('Example | select-align-item', function (hooks) {
  setupRenderingTest(hooks)

  test('the switch moves the list between over the trigger and below it', async function (assert) {
    await render(<template><SelectAlignItem /></template>)
    const field = new FieldHarness()
    assert.strictEqual(field.label, 'Align Item')
    assert.strictEqual(field.description, 'Toggle to align the item with the trigger.')
    assert.strictEqual(field.orientation, 'horizontal')
    const toggle = new SwitchHarness()
    assert.true(toggle.isChecked)
    assert.strictEqual(toggle.label, 'Align Item')

    const select = new SelectHarness()
    assert.strictEqual(select.valueText, 'Banana')
    await select.open()
    assert.strictEqual(select.position, 'item-aligned', 'the chosen item over the trigger')
    assert.dom(select.option('banana')).isFocused()
    await a11yAudit()
    await select.pressEscape()

    await toggle.click()
    assert.false(toggle.isChecked)
    await select.open()
    assert.strictEqual(select.position, 'popper', 'below the trigger')
    assert.strictEqual(select.side, 'bottom')
    await select.pressOption('grapes')
    assert.strictEqual(select.valueText, 'Grapes')
    await a11yAudit()
  })
})
