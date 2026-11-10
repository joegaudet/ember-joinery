import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DatePickerHarness } from '@ember-joinery/power-calendar/test-support'
import PowerDateRangePickerDemo from 'docs-app/examples/power-date-range-picker-demo'

module('Example | power-date-range-picker-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('three weeks from January 20th, chosen again in two presses', async function (assert) {
    await render(<template><PowerDateRangePickerDemo /></template>)
    const range = new DatePickerHarness('range')

    assert.strictEqual(range.text, 'Jan 20 – Feb 9, 2026')
    assert.strictEqual(range.label, 'Date Picker Range Jan 20 – Feb 9, 2026')
    await range.open()
    assert.strictEqual(range.calendar.month, 'January 2026')
    assert.strictEqual(range.calendar.focusedDay, '2026-01-20', 'focus on its first day')

    await range.calendar.select('2026-01-05')
    assert.true(range.isOpen)
    await range.calendar.select('2026-01-09')
    assert.false(range.isOpen)
    assert.strictEqual(range.text, 'Jan 5 – 9, 2026')
    await a11yAudit()
  })
})
