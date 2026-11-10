import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness } from '@ember-joinery/test-support'
import { DataTableHarness } from '@ember-joinery/data-table/test-support'
import DataTableDemo from 'docs-app/examples/data-table-demo'

module('Example | data-table-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('payments: filter, sort, select, hide columns and page through them', async function (assert) {
    await render(<template><DataTableDemo /></template>)
    const payments = new DataTableHarness()

    assert.deepEqual(payments.columns, ['', 'Status', 'Email', 'Amount', 'Actions'])
    assert.deepEqual(payments.columnIds, ['select', 'status', 'email', 'amount', 'actions'])
    assert.deepEqual(payments.column('status'), [
      'success',
      'success',
      'processing',
      'success',
      'failed',
    ])
    assert.deepEqual(payments.column('amount'), [
      '$316.00',
      '$242.00',
      '$837.00',
      '$874.00',
      '$721.00',
    ])
    assert.strictEqual(payments.filterInput('email').placeholder, 'Filter emails...')
    assert.false(payments.canPreviousPage, 'five payments: one page')
    assert.false(payments.canNextPage)
    await a11yAudit()

    await payments.filter('ken')
    assert.deepEqual(payments.column('email'), ['ken99@example.com'])
    await payments.filter('nobody')
    assert.strictEqual(payments.emptyText, 'No results.')
    await payments.filter('')

    await payments.sort('email')
    assert.strictEqual(payments.sortOf('email'), 'ascending')
    assert.deepEqual(payments.column('email'), [
      'Abe45@example.com',
      'carmella@example.com',
      'ken99@example.com',
      'Monserrat44@example.com',
      'Silas22@example.com',
    ])
    await payments.sort('email')
    assert.strictEqual(payments.sortOf('email'), 'descending')

    await payments.toggleRow(0)
    assert.deepEqual(payments.selectedRows, [0])
    assert.strictEqual(payments.selectAll!.state, 'indeterminate')
    assert.dom(payments.element).includesText('1 of 5 row(s) selected.')
    await payments.toggleAll()
    assert.deepEqual(payments.selectedRows, [0, 1, 2, 3, 4])
    assert.dom(payments.element).includesText('5 of 5 row(s) selected.')

    assert.deepEqual(await payments.columnOptions(), ['status', 'email', 'amount'])
    await payments.viewOptions.close()
    await payments.toggleColumn('amount')
    assert.false(payments.isColumnShown('amount'))
    await a11yAudit()
  })

  test('each row’s actions are a menu, at the row’s end', async function (assert) {
    await render(<template><DataTableDemo /></template>)
    const payments = new DataTableHarness()
    const actions = new DropdownMenuHarness({ within: payments.cell(0, 'actions') })
    assert.dom(actions.trigger).hasText('Open menu')
    assert.dom(actions.trigger).hasAttribute('data-size', 'icon-xs')
    await actions.open()
    assert.deepEqual(actions.labels, ['Actions'])
    assert.deepEqual(actions.items, ['Copy payment ID', 'View customer', 'View payment details'])
    assert.strictEqual(actions.align, 'end')
    await a11yAudit()
  })
})
