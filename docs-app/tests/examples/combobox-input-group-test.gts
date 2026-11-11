import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ComboboxHarness } from '@ember-joinery/test-support'
import ComboboxInputGroup from 'docs-app/examples/combobox-input-group'

module('Example | combobox-input-group', function (hooks) {
  setupRenderingTest(hooks)

  test('a globe addon before the input, and timezones in groups', async function (assert) {
    await render(<template><ComboboxInputGroup /></template>)
    const combobox = new ComboboxHarness()
    const addon = combobox.part('addon')
    assert
      .dom(addon)
      .hasClass('jn-input-group-addon')
      .hasClass('jn-input-group-addon-align-inline-start')
      .hasAttribute('data-align', 'inline-start')
    assert.dom('svg', addon).exists('the globe')
    const input = combobox.input!.getBoundingClientRect()
    assert.true(addon.getBoundingClientRect().right <= input.left + 1, 'the addon comes first')

    await click(addon)
    assert.true(combobox.isFocused, 'a press on the addon focuses the input')

    await combobox.open()
    assert.deepEqual(combobox.groups, ['Americas', 'Europe', 'Asia/Pacific'])
    assert.strictEqual(combobox.items.length, 18)
    assert.dom('[data-slot="combobox-separator"]', combobox.content).doesNotExist()
    assert.true(combobox.content!.offsetWidth >= 240, 'w-60, or the input group’s width and more')
    await a11yAudit()

    await combobox.type('tokyo')
    assert.deepEqual(combobox.items, ['(GMT+9) Tokyo'])
    await combobox.pressKey('ArrowDown')
    await combobox.pressKey('Enter')
    assert.strictEqual(combobox.inputValue, '(GMT+9) Tokyo')
    await a11yAudit()
  })
})
