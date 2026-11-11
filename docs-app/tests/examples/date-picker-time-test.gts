import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DatePickerHarness, FieldHarness, InputHarness } from '@ember-joinery/test-support'
import DatePickerTime from 'docs-app/examples/date-picker-time'

const monthName = (date: Date) => new Intl.DateTimeFormat('en-US', { month: 'long' }).format(date)

module('Example | date-picker-time', function (hooks) {
  setupRenderingTest(hooks)

  test('a date picker beside a time input, in one row', async function (assert) {
    await render(<template><DatePickerTime /></template>)
    const [date, time] = FieldHarness.findAll()
    const picker = new DatePickerHarness()
    const input = new InputHarness()
    assert.strictEqual(date?.label, 'Date')
    assert.strictEqual(time?.label, 'Time')
    assert.strictEqual(picker.text, 'Select date')
    assert.strictEqual(input.type, 'time')
    assert.strictEqual(input.value, '10:30:00')
    await a11yAudit()

    await picker.open()
    assert.ok(picker.calendar.yearDropdown(), 'month and year dropdowns')
    const today = new Date()
    const day = new Date(today.getFullYear(), today.getMonth(), 21)
    await picker.pick(day)
    assert.false(picker.isOpen, 'a pick closes it')
    assert.strictEqual(picker.text, `${monthName(day)} 21st, ${day.getFullYear()}`)

    await input.fillIn('08:15:30')
    assert.strictEqual(input.value, '08:15:30')
    await a11yAudit()
  })
})
