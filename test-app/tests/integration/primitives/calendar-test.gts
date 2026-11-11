import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { hash } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  Calendar,
  addDays,
  addToRange,
  calendarLocale,
  calendarSystem,
  isMatch,
  isoDate,
  parseIsoDate,
  weekInfo,
} from '@ember-joinery/primitives/calendar'
import { CalendarHarness } from '@ember-joinery/test-support'

const day = parseIsoDate

module('Integration | primitives | calendar', function (hooks) {
  setupRenderingTest(hooks)

  module('dates', function () {
    test('days are local midnights, moved by calendar days', function (assert) {
      const date = day('2026-03-28')
      assert.strictEqual(date.getHours(), 0)
      assert.strictEqual(isoDate(addDays(date, 3)), '2026-03-31')
      assert.strictEqual(isoDate(addDays(date, -28)), '2026-02-28')
      assert.strictEqual(isoDate(day('0099-05-01')), '0099-05-01', 'a year below 100 stays put')
    })

    test("the Gregorian system moves by months and years, keeping the day or the month's last", function (assert) {
      const gregory = calendarSystem('gregory')
      assert.strictEqual(isoDate(gregory.addMonths(day('2026-01-31'), 1)), '2026-02-28')
      assert.strictEqual(isoDate(gregory.addYears(day('2024-02-29'), 1)), '2025-02-28')
      assert.strictEqual(gregory.monthsInYear(2026), 12)
      assert.strictEqual(gregory.daysInMonth(day('2028-02-10')), 29)
      assert.strictEqual(calendarSystem('nonsense').id, 'gregory', 'one Intl does not know')
      assert.strictEqual(calendarSystem('buddhist').id, 'gregory', 'Gregorian months, other years')
    })

    test("a Persian calendar's months come from Intl, with no Jalali library", function (assert) {
      const persian = calendarSystem('persian')
      // 1 Farvardin 1405 is 21 March 2026; Esfand 1404 has 29 days.
      const nowruz = persian.monthStart(1405, 0)
      assert.strictEqual(isoDate(nowruz), '2026-03-21')
      assert.strictEqual(persian.year(nowruz), 1405)
      assert.strictEqual(persian.month(nowruz), 0)
      assert.strictEqual(persian.daysInMonth(addDays(nowruz, -1)), 29)
      assert.strictEqual(
        isoDate(persian.startOfMonth(day('2025-06-12'))),
        '2025-05-22',
        '1 Khordad',
      )
      assert.strictEqual(persian.monthsInYear(1404), 12)
      assert.strictEqual(isoDate(persian.addMonths(nowruz, -1)), '2026-02-20', '1 Esfand 1404')
      assert.strictEqual(persian.year(persian.addYears(nowruz, -100)), 1305)
    })

    test('a Hebrew year has 13 months in a leap year', function (assert) {
      const hebrew = calendarSystem('hebrew')
      assert.strictEqual(hebrew.monthsInYear(5784), 13, '5784 is a leap year')
      assert.strictEqual(hebrew.monthsInYear(5785), 12)
    })

    test("a locale's week comes from Intl", function (assert) {
      assert.deepEqual(weekInfo('en-US'), { firstDay: 0, minimalDays: 1 })
      assert.strictEqual(weekInfo('es').firstDay, 1, 'Monday')
      assert.strictEqual(weekInfo('fa-IR').firstDay, 6, 'Saturday')
      assert.strictEqual(weekInfo('de-DE').minimalDays, 4)
    })

    test('a locale formats in its calendar and numbering system, Gregorian and Latin by default', function (assert) {
      const arabic = calendarLocale('ar-SA')
      assert.strictEqual(arabic.calendar, 'gregory', "react-day-picker's default, not Intl's")
      assert.strictEqual(arabic.numerals, 'latn')
      assert.strictEqual(arabic.format(day('2026-01-12'), { day: 'numeric' }), '12')
      const persian = calendarLocale('fa-IR', 'persian', 'arabext')
      assert.strictEqual(persian.format(day('2026-03-21'), { day: 'numeric' }), '۱')
      assert.strictEqual(calendarLocale('ar-SA-u-nu-arab').numerals, 'arab', "the tag's own")
    })

    test("matchers are react-day-picker's", function (assert) {
      const date = day('2026-01-12') // a Monday
      assert.true(isMatch(date, true))
      assert.true(isMatch(date, day('2026-01-12')))
      assert.true(isMatch(date, [day('2026-01-01'), day('2026-01-12')]))
      assert.true(isMatch(date, { from: day('2026-01-10'), to: day('2026-01-14') }))
      assert.true(isMatch(date, { before: day('2026-01-13') }))
      assert.false(isMatch(date, { before: day('2026-01-12') }), 'before leaves the day out')
      assert.true(isMatch(date, { after: day('2026-01-11') }))
      assert.true(isMatch(date, { after: day('2026-01-10'), before: day('2026-01-14') }))
      assert.false(isMatch(date, { after: day('2026-01-14'), before: day('2026-01-10') }))
      assert.true(isMatch(date, { dayOfWeek: [0, 1] }))
      assert.true(isMatch(date, (d: Date) => d.getDate() === 12))
      assert.false(isMatch(date, undefined))
    })

    test("a range grows as react-day-picker's addToRange grows it", function (assert) {
      const a = day('2026-01-10')
      const b = day('2026-01-14')
      const first = addToRange(a, undefined)
      assert.deepEqual(first, { from: a, to: a }, 'a first press is a one-day range')
      assert.deepEqual(addToRange(b, first), { from: a, to: b })
      assert.deepEqual(addToRange(day('2026-01-05'), { from: a, to: b }), {
        from: day('2026-01-05'),
        to: b,
      })
      assert.strictEqual(
        addToRange(a, { from: a, to: a }),
        undefined,
        'the same day again empties it',
      )
      assert.deepEqual(
        addToRange(a, { from: a, to: a }, 0, 0, true),
        { from: a, to: a },
        'unless required',
      )
      assert.deepEqual(
        addToRange(day('2026-01-30'), { from: a, to: undefined }, 0, 7),
        { from: day('2026-01-30'), to: undefined },
        'a range past @max starts again',
      )
    })
  })

  test("the headless calendar renders react-day-picker's markup and classes, unstyled", async function (assert) {
    const today = day('2026-01-15')
    await render(<template><Calendar @mode="single" @today={{today}} @name="plain" /></template>)
    const calendar = new CalendarHarness('plain')
    assert.dom(calendar.element).hasClass('rdp-root').doesNotHaveAttribute('data-slot')
    assert.strictEqual(calendar.caption, 'January 2026')
    assert.dom(calendar.grids[0]).hasClass('rdp-month_grid').hasAttribute('role', 'grid')
    assert.dom(calendar.previousButton.querySelector('svg')).hasClass('rdp-chevron')
    assert.deepEqual(calendar.weekdays, ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'])
    assert.true(
      calendar.isHidden('2025-12-28'),
      'no outside days by default: their cells are hidden',
    )
    assert.dom('button', calendar.cell('2025-12-28')).doesNotExist()
    assert.dom(calendar.cell('2026-01-15')).hasClass('rdp-day').hasClass('rdp-today')
    await a11yAudit()
  })

  test('@classNames replaces the classes of the parts it names', async function (assert) {
    const today = day('2026-01-15')
    await render(
      <template>
        <Calendar
          @mode="single"
          @today={{today}}
          @classNames={{hash day="cell" today="cell-today" day_button="day"}}
        />
      </template>,
    )
    const calendar = new CalendarHarness()
    assert.dom(calendar.cell('2026-01-15')).hasClass('cell').hasClass('cell-today')
    assert.dom(calendar.cell('2026-01-15')).doesNotHaveClass('rdp-day')
    assert.dom(calendar.button('2026-01-15')).hasClass('day')
    await a11yAudit()
  })

  test('a <:chevron> block draws the chevrons, told which way each points', async function (assert) {
    const today = day('2026-01-15')
    await render(
      <template>
        <Calendar @mode="single" @today={{today}} @captionLayout="dropdown">
          <:chevron as |orientation className|>
            <span class={{className}} data-orientation={{orientation}}></span>
          </:chevron>
        </Calendar>
      </template>,
    )
    const calendar = new CalendarHarness()
    assert.dom('[data-orientation="left"]', calendar.previousButton).exists()
    assert.dom('[data-orientation="right"]', calendar.nextButton).exists()
    assert.dom('[data-orientation="down"].rdp-chevron', calendar.element).exists({ count: 2 })
    await a11yAudit()
  })
})
