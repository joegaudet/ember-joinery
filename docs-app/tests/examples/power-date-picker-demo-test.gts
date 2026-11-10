import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DatePickerHarness } from '@ember-joinery/power-calendar/test-support'
import PowerDatePickerDemo from 'docs-app/examples/power-date-picker-demo'

module('Example | power-date-picker-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a check-in day and a stay, each chosen in its calendar', async function (assert) {
    await render(<template><PowerDatePickerDemo /></template>)
    const checkIn = new DatePickerHarness('check-in')
    const stay = new DatePickerHarness('stay')

    assert.strictEqual(checkIn.label, 'Check-in November 12, 2026', 'its label, then its value')
    assert.strictEqual(stay.text, 'Nov 12 – 16, 2026')
    assert.true(stay.isRange)

    await checkIn.open()
    assert.strictEqual(checkIn.calendar.focusedDay, '2026-11-12', 'it opens on the day chosen')
    await checkIn.calendar.select('2026-11-14')
    assert.strictEqual(checkIn.text, 'November 14, 2026')
    assert.false(checkIn.isOpen)

    await stay.open()
    await stay.calendar.select('2026-11-20')
    assert.strictEqual(stay.text, 'Nov 12 – 16, 2026', 'one night chosen: the stay is as it was')
    await stay.calendar.select('2026-11-23')
    assert.strictEqual(stay.text, 'Nov 20 – 23, 2026')
    assert.false(stay.isOpen)
    await a11yAudit()
  })
})
