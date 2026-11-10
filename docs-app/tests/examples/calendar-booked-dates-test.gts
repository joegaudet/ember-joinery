import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CalendarHarness } from '@ember-joinery/test-support'
import CalendarBookedDates from 'docs-app/examples/calendar-booked-dates'

module('Example | calendar-booked-dates', function (hooks) {
  setupRenderingTest(hooks)

  test('the booked days are struck through and can’t be picked', async function (assert) {
    await render(<template><CalendarBookedDates /></template>)
    const calendar = new CalendarHarness()
    const year = new Date().getFullYear()
    assert.strictEqual(calendar.caption, `February ${year}`)
    assert.true(calendar.isSelected(new Date(year, 1, 3)))
    const booked = new Date(year, 1, 12)
    assert.true(calendar.isDisabled(booked))
    assert.strictEqual(calendar.disabledDays.length, 15)
    const button = getComputedStyle(calendar.button(booked))
    assert.strictEqual(button.textDecorationLine, 'line-through')
    assert.strictEqual(getComputedStyle(calendar.cell(booked)).opacity, '1', 'opacity-100')
    assert.false(calendar.isDisabled(new Date(year, 1, 11)))
    await calendar.select(new Date(year, 1, 9))
    assert.true(calendar.isSelected(new Date(year, 1, 9)))
    await a11yAudit()
  })
})
