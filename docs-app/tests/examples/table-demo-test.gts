import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TableHarness } from '@ember-joinery/test-support'
import TableDemo from 'docs-app/examples/table-demo'

module('Example | table-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('seven invoices, a total, and a caption', async function (assert) {
    await render(<template><TableDemo /></template>)
    const invoices = new TableHarness()

    assert.strictEqual(invoices.caption, 'A list of your recent invoices.')
    assert.deepEqual(invoices.columns, ['Invoice', 'Status', 'Method', 'Amount'])
    assert.strictEqual(invoices.rowCount, 7)
    assert.deepEqual(invoices.rows[0], ['INV001', 'Paid', 'Credit Card', '$250.00'])
    assert.deepEqual(invoices.column('Status'), [
      'Paid',
      'Pending',
      'Unpaid',
      'Paid',
      'Paid',
      'Pending',
      'Unpaid',
    ])
    assert.deepEqual(invoices.footer, [['Total', '$2,500.00']])
    assert.strictEqual(
      getComputedStyle(invoices.cell(0, 'Amount')).textAlign,
      'right',
      'text-right',
    )
    assert.strictEqual(getComputedStyle(invoices.cell(0, 0)).fontWeight, '500', 'font-medium')
    await a11yAudit()
  })
})
