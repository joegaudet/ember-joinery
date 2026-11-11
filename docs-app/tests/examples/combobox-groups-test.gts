import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ComboboxHarness } from '@ember-joinery/test-support'
import ComboboxGroups from 'docs-app/examples/combobox-groups'

module('Example | combobox-groups', function (hooks) {
  setupRenderingTest(hooks)

  test('timezones in three groups, filtered group by group', async function (assert) {
    await render(<template><ComboboxGroups /></template>)
    const combobox = new ComboboxHarness()
    await combobox.open()
    assert.deepEqual(combobox.groups, ['Americas', 'Europe', 'Asia/Pacific'])
    assert.strictEqual(combobox.items.length, 18)
    assert.dom('[data-slot="combobox-separator"]', combobox.content).exists({ count: 2 })
    await a11yAudit()

    await combobox.type('gmt+1)')
    assert.deepEqual(combobox.groups, ['Europe', 'Asia/Pacific'])
    assert.deepEqual(combobox.items, [
      '(GMT+1) Paris',
      '(GMT+1) Berlin',
      '(GMT+1) Rome',
      '(GMT+1) Madrid',
      '(GMT+1) Amsterdam',
      '(GMT+11) Sydney',
    ])
    await combobox.pressKey('ArrowUp')
    assert.strictEqual(combobox.highlighted, '(GMT+11) Sydney', 'ArrowUp goes round to the last')
    await combobox.pressKey('Enter')
    assert.strictEqual(combobox.inputValue, '(GMT+11) Sydney')
    await a11yAudit()
  })
})
