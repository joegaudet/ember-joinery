import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DropdownMenuHarness, TableHarness } from '@ember-joinery/test-support'
import TableActions from 'docs-app/examples/table-actions'

module('Example | table-actions', function (hooks) {
  setupRenderingTest(hooks)

  test('each product has a menu of actions at the row’s end', async function (assert) {
    await render(<template><TableActions /></template>)
    const table = new TableHarness()
    assert.deepEqual(table.columns, ['Product', 'Price', 'Actions'])
    assert.deepEqual(table.column('Product'), [
      'Wireless Mouse',
      'Mechanical Keyboard',
      'USB-C Hub',
    ])
    assert.deepEqual(table.column('Price'), ['$29.99', '$129.99', '$49.99'])

    const menus = DropdownMenuHarness.findAll()
    assert.strictEqual(menus.length, 3, 'one per row')
    const [, keyboard] = menus
    const button = new ButtonHarness({ within: table.cell(1, 'Actions') })
    assert.strictEqual(button.label, 'Open menu')
    assert.strictEqual(button.size, 'icon')
    assert.strictEqual(keyboard!.trigger, button.element)
    await a11yAudit()

    await keyboard!.open()
    assert.deepEqual(keyboard!.items, ['Edit', 'Duplicate', 'Delete'])
    assert.strictEqual(keyboard!.align, 'end')
    assert.strictEqual(keyboard!.variant('Delete'), 'destructive')
    await a11yAudit()
  })
})
