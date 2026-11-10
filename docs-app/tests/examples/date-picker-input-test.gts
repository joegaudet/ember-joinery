import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  DatePickerHarness,
  FieldHarness,
  InputGroupHarness,
  pressKey,
} from '@ember-joinery/test-support'
import DatePickerInput from 'docs-app/examples/date-picker-input'

const written = (date: Date) =>
  date.toLocaleDateString('en-US', { day: '2-digit', month: 'long', year: 'numeric' })

module('Example | date-picker-input', function (hooks) {
  setupRenderingTest(hooks)

  test('type a date or pick one: ArrowDown or the calendar button opens it, and a pick writes the input', async function (assert) {
    await render(<template><DatePickerInput /></template>)
    // Upstream's date, `new Date("2025-06-01")`: midnight UTC, so the 1st or the 31st of May.
    const start = new Date('2025-06-01')
    const field = new FieldHarness()
    const input = new InputGroupHarness()
    const picker = new DatePickerHarness()
    assert.strictEqual(field.label, 'Subscription Date')
    assert.strictEqual(input.value, written(start))
    assert.strictEqual(input.placeholder, 'June 01, 2025')
    assert.strictEqual(picker.trigger.getAttribute('aria-label'), 'Select date')
    await a11yAudit()

    await input.focus()
    await pressKey('ArrowDown')
    assert.true(picker.isOpen, 'ArrowDown in the input opens it')
    assert.true(picker.calendar.isSelected(start))
    assert.strictEqual(picker.align, 'end')
    await a11yAudit()

    await picker.pick('2025-06-15')
    assert.false(picker.isOpen, 'a pick closes it')
    assert.strictEqual(input.value, 'June 15, 2025')

    await input.fillIn('July 04, 2025')
    await picker.open()
    assert.deepEqual(picker.calendar.months, ['2025-07-01'], 'the calendar follows what you type')
    assert.true(picker.calendar.isSelected('2025-07-04'))
    await a11yAudit()
  })
})
