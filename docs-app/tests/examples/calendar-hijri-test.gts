import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CalendarHarness } from '@ember-joinery/test-support'
import CalendarHijri from 'docs-app/examples/calendar-hijri'

module('Example | calendar-hijri', function (hooks) {
  setupRenderingTest(hooks)

  test('a Persian month, right to left, in Persian digits', async function (assert) {
    await render(<template><CalendarHijri /></template>)
    const calendar = new CalendarHarness()
    assert.dom(calendar.element).hasAttribute('dir', 'rtl')
    assert.deepEqual(calendar.months, ['2025-05-22'], 'Khordad 1404 starts on 22 May 2025')
    assert.true(calendar.caption.includes('خرداد'))
    assert.true(calendar.isSelected('2025-06-12'))
    assert.strictEqual(calendar.dayText('2025-06-12'), '۲۲', '22 Khordad')
    assert.strictEqual(calendar.weekdayLabels[0], 'شنبه', 'the week starts on Saturday')
    await calendar.previous()
    assert.deepEqual(calendar.months, ['2025-04-21'], 'Ordibehesht')
    await a11yAudit()
  })
})
