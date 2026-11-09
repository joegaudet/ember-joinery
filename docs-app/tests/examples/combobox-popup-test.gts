import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, ComboboxHarness } from '@ember-joinery/test-support'
import ComboboxPopup from 'docs-app/examples/combobox-popup'

module('Example | combobox-popup', function (hooks) {
  setupRenderingTest(hooks)

  test('a button opens a popup with its own search, and shows the country chosen', async function (assert) {
    await render(<template><ComboboxPopup /></template>)
    const combobox = new ComboboxHarness()
    const button = new ButtonHarness()
    assert.strictEqual(button.variant, 'outline')
    assert.strictEqual(button.element, combobox.trigger, 'the Button is the trigger')
    assert.dom(combobox.trigger).hasText('Select country').hasAttribute('role', 'combobox')

    await combobox.pressTrigger()
    assert.true(combobox.isOpen)
    assert.dom(combobox.input).isFocused('focus goes to the search')
    assert.strictEqual(combobox.items.length, 20)
    await a11yAudit()

    await combobox.type('ger')
    assert.deepEqual(combobox.items, ['Germany', 'Nigeria'])
    await combobox.pressItem('Germany')
    assert.false(combobox.isOpen)
    assert.dom(combobox.trigger).hasText('Germany').isFocused()
    await a11yAudit()
  })
})
