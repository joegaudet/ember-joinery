import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness } from '@ember-joinery/test-support'
import DropdownMenuCheckboxes from 'docs-app/examples/dropdown-menu-checkboxes'

module('Example | dropdown-menu-checkboxes', function (hooks) {
  setupRenderingTest(hooks)

  test('checkbox items toggle, but the disabled one', async function (assert) {
    await render(<template><DropdownMenuCheckboxes /></template>)
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.deepEqual(menu.labels, ['Appearance'])
    assert.deepEqual(menu.items, ['Status Bar', 'Activity Bar', 'Panel'])
    assert.true(menu.isChecked('Status Bar'))
    assert.false(menu.isChecked('Activity Bar'))
    assert.true(menu.isDisabled('Activity Bar'))
    assert.false(menu.isChecked('Panel'))
    assert.dom('svg', menu.item('Status Bar')).exists('a check mark')
    assert.dom('svg', menu.item('Panel')).doesNotExist()
    await a11yAudit()

    await menu.select('Panel')
    await menu.open()
    assert.true(menu.isChecked('Panel'))
    await menu.select('Status Bar')
    await menu.open()
    assert.false(menu.isChecked('Status Bar'))
    await a11yAudit()
  })
})
