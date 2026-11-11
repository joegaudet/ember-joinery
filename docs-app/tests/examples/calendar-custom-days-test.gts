import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CalendarHarness } from '@ember-joinery/test-support'
import CalendarCustomDays from 'docs-app/examples/calendar-custom-days'

module('Example | calendar-custom-days', function (hooks) {
  setupRenderingTest(hooks)

  test('each day of the month shows its price, and its name says it', async function (assert) {
    await render(<template><CalendarCustomDays /></template>)
    const calendar = new CalendarHarness()
    const year = new Date().getFullYear()
    const monday = new Date(
      year,
      11,
      [1, 2, 3, 4, 5, 6, 7].find(d => new Date(year, 11, d).getDay() === 1)!,
    )
    const saturday = new Date(year, 11, monday.getDate() + 5)
    assert.strictEqual(calendar.caption, `December ${year}`)
    assert.strictEqual(calendar.dayText(monday), `${monday.getDate()} $100`)
    assert.strictEqual(calendar.dayText(saturday), `${saturday.getDate()} $120`)
    assert.true(calendar.dayLabel(monday).startsWith(`${monday.getDate()} $100, `))
    assert.strictEqual(calendar.rangePosition(new Date(year, 11, 8)), 'start')
    assert.strictEqual(calendar.rangePosition(new Date(year, 11, 18)), 'end')
    assert.strictEqual(
      calendar.monthOptions()[0],
      new Date(year, 0, 1).toLocaleString('default', { month: 'long' }),
    )
    await a11yAudit()
  })
})
