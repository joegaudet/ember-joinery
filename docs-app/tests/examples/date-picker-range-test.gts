import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DatePickerHarness, FieldHarness } from '@ember-joinery/test-support'
import DatePickerRange from 'docs-app/examples/date-picker-range'

module('Example | date-picker-range', function (hooks) {
  setupRenderingTest(hooks)

  test('the button shows the range, 20 January for twenty nights, and two months pick another', async function (assert) {
    await render(<template><DatePickerRange /></template>)
    const year = new Date().getFullYear()
    const field = new FieldHarness()
    const picker = new DatePickerHarness()
    assert.strictEqual(field.label, 'Date Picker Range')
    assert.strictEqual(picker.text, `Jan 20, ${year} - Feb 09, ${year}`)
    assert.strictEqual(picker.trigger.querySelectorAll('svg').length, 1, 'a calendar icon')
    await a11yAudit()

    await picker.open()
    assert.deepEqual(picker.calendar.captions, [`January ${year}`, `February ${year}`])
    assert.strictEqual(picker.calendar.rangePosition(new Date(year, 0, 20)), 'start')
    assert.strictEqual(picker.calendar.rangePosition(new Date(year, 1, 9)), 'end')
    assert.strictEqual(picker.calendar.selectedDays.length, 21)

    await picker.pickRange(new Date(year, 0, 5), new Date(year, 1, 2))
    assert.strictEqual(picker.text, `Jan 05, ${year} - Feb 02, ${year}`)
    assert.strictEqual(picker.calendar.rangePosition(new Date(year, 0, 5)), 'start')
    assert.strictEqual(picker.calendar.rangePosition(new Date(year, 1, 2)), 'end')

    // A range after the one it holds: the first press would only move its end.
    await picker.pickRange(new Date(year, 2, 1), new Date(year, 2, 5))
    assert.strictEqual(picker.text, `Mar 01, ${year} - Mar 05, ${year}`)
    assert.strictEqual(picker.calendar.selectedDays.length, 5)
    await a11yAudit()
  })
})
