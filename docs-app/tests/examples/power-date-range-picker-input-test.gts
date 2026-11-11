import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DatePickerHarness } from '@ember-joinery/power-calendar/test-support'
import PowerDateRangePickerInput from 'docs-app/examples/power-date-range-picker-input'

module('Example | power-date-range-picker-input', function (hooks) {
  setupRenderingTest(hooks)

  test('both dates typed, or chosen in the calendar', async function (assert) {
    await render(<template><PowerDateRangePickerInput /></template>)
    const trip = new DatePickerHarness('trip')

    assert.strictEqual(trip.label, 'Trip')
    assert.true(trip.isEmpty)
    assert.strictEqual(trip.triggerLabel, 'Select dates')

    await trip.typeDate('Mar 4, 2026 - Mar 9, 2026')
    assert.strictEqual(trip.text, 'Mar 4, 2026 – Mar 9, 2026')

    await trip.open()
    assert.strictEqual(trip.calendar.selected.length, 6)
    await trip.calendar.selectRange('2026-03-16', '2026-03-20')
    assert.strictEqual(trip.text, 'Mar 16, 2026 – Mar 20, 2026')
    assert.dom(trip.input).isFocused()
    await a11yAudit()
  })
})
