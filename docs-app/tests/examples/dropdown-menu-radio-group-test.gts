import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness } from '@ember-joinery/test-support'
import DropdownMenuRadioGroup from 'docs-app/examples/dropdown-menu-radio-group'

module('Example | dropdown-menu-radio-group', function (hooks) {
  setupRenderingTest(hooks)

  test('one panel position checked at a time', async function (assert) {
    await render(<template><DropdownMenuRadioGroup /></template>)
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.strictEqual(getComputedStyle(menu.content!).width, '128px', 'w-32')
    assert.deepEqual(menu.labels, ['Panel Position'])
    assert.deepEqual(menu.items, ['Top', 'Bottom', 'Right'])
    assert.strictEqual(menu.role('Top'), 'menuitemradio')
    assert.deepEqual(
      menu.items.map(item => menu.isChecked(item)),
      [false, true, false],
    )
    await a11yAudit()

    await menu.select('Right')
    await menu.open()
    assert.deepEqual(
      menu.items.map(item => menu.isChecked(item)),
      [false, false, true],
    )
    await a11yAudit()
  })
})
