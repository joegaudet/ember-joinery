import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TableHarness } from '@ember-joinery/test-support'
import TableFooter from 'docs-app/examples/table-footer'

module('Example | table-footer', function (hooks) {
  setupRenderingTest(hooks)

  test('three invoices over a footer with the total', async function (assert) {
    await render(<template><TableFooter /></template>)
    const invoices = new TableHarness()

    assert.deepEqual(invoices.column('Invoice'), ['INV001', 'INV002', 'INV003'])
    assert.deepEqual(invoices.footer, [['Total', '$2,500.00']])
    const total = invoices.table.tFoot!.rows[0]!.cells[0]!
    assert.strictEqual(total.colSpan, 3, 'Total spans three columns')
    assert.strictEqual(
      getComputedStyle(invoices.part('footer')).fontWeight,
      '500',
      'the footer is medium weight',
    )
    await a11yAudit()
  })
})
