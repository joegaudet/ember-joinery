import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { TableHarness } from '@ember-joinery/test-support'
import TableRtl from 'docs-app/examples/table-rtl'

module('Example | table-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, the first column on the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><TableRtl /></DirectionProvider>
      </template>,
    )
    const invoices = new TableHarness()
    assert.strictEqual(invoices.caption, 'قائمة بفواتيرك الأخيرة.')
    assert.deepEqual(invoices.columns, ['الفاتورة', 'الحالة', 'الطريقة', 'المبلغ'])
    assert.deepEqual(invoices.rows[2], ['INV003', 'غير مدفوع', 'تحويل بنكي', '$350.00'])
    assert.deepEqual(invoices.footer, [['المجموع', '$2,500.00']])

    const table = invoices.element.getBoundingClientRect()
    const first = invoices.cell(0, 0).getBoundingClientRect()
    assert.ok(Math.abs(first.right - table.right) < 1, 'the invoice column is on the right')
    assert.strictEqual(
      getComputedStyle(invoices.part('head')).textAlign,
      'start',
      'a header cell starts on the right',
    )
    await a11yAudit()
  })
})
