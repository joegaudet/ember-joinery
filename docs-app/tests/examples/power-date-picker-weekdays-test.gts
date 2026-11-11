import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DatePickerHarness } from '@ember-joinery/power-calendar/test-support'
import PowerDatePickerWeekdays from 'docs-app/examples/power-date-picker-weekdays'

module('Example | power-date-picker-weekdays', function (hooks) {
  setupRenderingTest(hooks)

  test('a weekday in November or December, written in full', async function (assert) {
    await render(<template><PowerDatePickerWeekdays /></template>)
    const shipsOn = new DatePickerHarness('ships-on')

    assert.strictEqual(shipsOn.text, 'Wednesday, November 18, 2026')
    assert.dom(shipsOn.trigger).hasAttribute('aria-describedby', 'ships-on-hint')
    await shipsOn.open()
    const calendar = shipsOn.calendar
    assert.true(calendar.isDayDisabled('2026-11-21'), 'a Saturday')
    assert.true(calendar.isDayDisabled('2026-11-01'), 'before November 2nd')
    assert.true(calendar.isPreviousDisabled)

    await calendar.focusDay('2026-11-20')
    await calendar.pressKey('ArrowRight')
    assert.strictEqual(calendar.focusedDay, '2026-11-23', 'the keyboard passes over the weekend')

    await shipsOn.select('2026-12-04')
    assert.strictEqual(shipsOn.text, 'Friday, December 4, 2026')
    await a11yAudit()
  })
})
