import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness } from '@ember-joinery/test-support'
import { DataTableHarness } from '@ember-joinery/data-table/test-support'
import DataTableRtl from 'docs-app/examples/data-table-rtl'

module('Example | data-table-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, right to left: the columns run from the right', async function (assert) {
    await render(
      <template>
        <div dir="rtl"><DataTableRtl /></div>
      </template>,
    )
    const payments = new DataTableHarness()
    assert.deepEqual(payments.columns, ['', 'الحالة', 'البريد الإلكتروني', 'المبلغ', 'الإجراءات'])
    assert.deepEqual(payments.column('status'), ['ناجح', 'ناجح', 'قيد المعالجة', 'ناجح', 'فشل'])
    const amount = new Intl.NumberFormat('ar-SA', { style: 'currency', currency: 'USD' })
    assert.strictEqual(
      payments.column('amount')[0],
      amount.format(316).replace(/\s+/g, ' '),
      'in Arabic numerals',
    )
    const [first, , , , last] = payments.columnHeads
    assert.true(
      first!.getBoundingClientRect().left > last!.getBoundingClientRect().left,
      'select all is at the right, the actions at the left',
    )
    assert.strictEqual(payments.selectAll!.label, 'تحديد الكل')
    assert.strictEqual(payments.rowCheckbox(0)!.label, 'تحديد الصف')
    assert.dom(payments.element).includesText('0 من 5 صف(وف) محدد.')

    await payments.sort('البريد الإلكتروني')
    assert.strictEqual(payments.sortOf('email'), 'ascending')
    await payments.filter('nobody')
    assert.strictEqual(payments.emptyText, 'لا توجد نتائج.')
    await payments.filter('')

    assert.deepEqual(await payments.columnOptions(), ['status', 'email', 'amount'])
    assert.strictEqual(payments.viewOptions.align, 'start', 'at the trigger’s inline start')
    assert.dom(payments.viewOptions.content).hasAttribute('data-lang', 'ar')
    await payments.viewOptions.close()

    const actions = new DropdownMenuHarness({ within: payments.cell(0, 'actions') })
    await actions.open()
    assert.deepEqual(actions.items, ['نسخ معرف الدفع', 'عرض العميل', 'عرض تفاصيل الدفع'])
    assert.strictEqual(actions.separators, 1)
    await a11yAudit()
  })
})
