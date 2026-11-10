import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, rerender } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { array } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { tab } from '@ember-joinery/test-support'
import {
  PowerCalendar,
  PowerCalendarMultiple,
  PowerCalendarRange,
  toIsoDate,
  type DateRange,
} from '@ember-joinery/power-calendar'
import { PowerCalendarHarness } from '@ember-joinery/power-calendar/test-support'

/** What a test changes between renders, and what the calendar sent. */
class State {
  @tracked value: Date | undefined = undefined
  @tracked range: DateRange | undefined = undefined
  @tracked days: Date[] = []
  @tracked center: Date | undefined = new Date(2026, 2, 1)
  @tracked disabled = false
  sent: unknown[] = []
  record = (value: unknown) => {
    this.sent.push(value)
  }
  keep = (value: Date | undefined) => {
    this.sent.push(value)
    this.value = value
  }
  keepRange = (range: DateRange) => {
    this.sent.push(range)
    this.range = range
  }
  keepDays = (days: Date[]) => {
    this.sent.push(days)
    this.days = days
  }
  keepCenter = (center: Date) => {
    this.sent.push(center)
    this.center = center
  }
}

const iso = (value: unknown) =>
  value instanceof Date ? toIsoDate(value) : value === undefined ? undefined : String(value)
const isoRange = (range: unknown) => {
  const { from, to } = (range ?? {}) as DateRange
  return { from: iso(from), to: iso(to) }
}

const MARCH_4 = new Date(2026, 2, 4)
const MARCH_1 = new Date(2026, 2, 1)

module('Integration | components | power-calendar', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders shadcn's Calendar on ember-power-calendar", async function (assert) {
    await render(
      <template>
        <PowerCalendar
          @name="due"
          @defaultValue={{MARCH_4}}
          @locale="en-US"
          class="rounded-lg border custom"
        />
      </template>,
    )
    const calendar = new PowerCalendarHarness('due')

    assert
      .dom(calendar.element)
      .hasClass('jn-calendar', "each style sheet's Calendar rule applies")
      .hasClass('jn-power-calendar')
      .hasClass('group/calendar')
      .hasClass('ember-power-calendar', "it is ember-power-calendar's root")
      .hasClass('custom', '...attributes adds a class')
      .hasAttribute('data-slot', 'calendar')
      .hasAttribute('data-test-jn', 'power-calendar')
      .hasAttribute('data-test-jn-name', 'due')
      .hasAttribute('role', 'group')
      .hasAttribute('aria-label', 'Choose date')
    assert.strictEqual(calendar.kind, 'single')
    assert.strictEqual(calendar.label, 'Choose date')
    assert.strictEqual(calendar.month, 'March 2026')
    assert.strictEqual(calendar.shownMonth, '2026-03')
    assert.deepEqual(calendar.weekdays, ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
    assert.deepEqual(calendar.weekdayNames, [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ])
    assert.strictEqual(calendar.days.length, 31)
    assert.deepEqual(calendar.selected, ['2026-03-04'])

    const caption = calendar.part('caption')
    assert
      .dom(calendar.grid)
      .hasAttribute('role', 'grid')
      .hasAttribute('aria-labelledby', caption.id)
      .doesNotHaveAttribute('aria-multiselectable')
      .hasAttribute('data-slot', 'calendar-grid')
    assert.dom(caption).hasAttribute('aria-live', 'polite')

    const day = calendar.day('2026-03-04')!
    assert
      .dom(day)
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasAttribute('role', 'gridcell')
      .hasAttribute('aria-selected', 'true')
      .hasAttribute('aria-label', 'Wednesday, March 4, 2026')
      .hasAttribute('data-selected-single', 'true')
      .hasAttribute('data-test-jn-value', '2026-03-04')
      .hasClass('jn-button')
      .hasClass('jn-button-variant-ghost')
      .hasClass('jn-button-size-icon')
      .hasClass('jn-power-calendar-day-button')
      .hasText('4')
    assert.dom(day.parentElement).hasAttribute('data-selected', 'true')
    assert.strictEqual(calendar.dayLabel('2026-03-05'), 'Thursday, March 5, 2026')
    assert.dom(calendar.day('2026-03-05')).hasAttribute('aria-selected', 'false')

    // The days around the month fill its first and last weeks, muted.
    const outside = calendar.anyDay('2026-04-01')!
    assert.dom(outside.parentElement).hasAttribute('data-outside', 'true')
    assert.strictEqual(calendar.day('2026-04-01'), null, 'day() reads the month shown only')

    assert.dom(calendar.previousButton).hasAttribute('aria-label', 'Previous month')
    assert.dom(calendar.nextButton).hasAttribute('aria-label', 'Next month')
    assert.dom(calendar.previousButton).hasClass('jn-button-variant-ghost')
    assert.dom('svg', calendar.previousButton).hasClass('jn-rtl-flip')
    await a11yAudit()
  })

  test("the style sheets draw it: Nova's cell size, padding and a filled chosen day", async function (assert) {
    await render(
      <template><PowerCalendar @name="due" @defaultValue={{MARCH_4}} @locale="en-US" /></template>,
    )
    const calendar = new PowerCalendarHarness('due')
    const root = getComputedStyle(calendar.element)
    assert.strictEqual(root.paddingTop, '8px', "Nova's p-2")
    const day = calendar.day('2026-03-05')!
    assert.strictEqual(day.offsetWidth, 28, "Nova's --cell-size, 1.75rem")
    assert.strictEqual(day.offsetHeight, 28)
    const chosen = getComputedStyle(calendar.day('2026-03-04')!)
    const plain = getComputedStyle(day)
    assert.notEqual(chosen.backgroundColor, plain.backgroundColor, 'the chosen day is filled')
    assert.notEqual(chosen.color, plain.color, 'in --primary-foreground')
    assert.strictEqual(calendar.previousButton.offsetWidth, 28, 'the nav buttons are a cell wide')
    const weekday = getComputedStyle(calendar.parts('weekday')[0]!)
    assert.strictEqual(weekday.textAlign, 'center')
    assert.strictEqual(weekday.fontSize, '12.8px', 'text-[0.8rem]')
    await a11yAudit()
  })

  test('uncontrolled, it keeps the day chosen; the chosen day pressed again clears it', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PowerCalendar
          @name="due"
          @defaultValue={{MARCH_4}}
          @onValueChange={{state.record}}
          @locale="en-US"
        />
      </template>,
    )
    const calendar = new PowerCalendarHarness('due')
    await calendar.select('2026-03-10')
    assert.deepEqual(calendar.selected, ['2026-03-10'])
    await calendar.select('2026-03-10')
    assert.deepEqual(calendar.selected, [], 'pressing it again clears it, as upstream does')
    assert.deepEqual(state.sent.map(iso), ['2026-03-10', undefined])
    await a11yAudit()
  })

  test('@required keeps the chosen day when it is pressed again', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PowerCalendar
          @name="due"
          @defaultValue={{MARCH_4}}
          @required={{true}}
          @onValueChange={{state.record}}
        />
      </template>,
    )
    const calendar = new PowerCalendarHarness('due')
    await calendar.select('2026-03-04')
    assert.deepEqual(calendar.selected, ['2026-03-04'])
    assert.deepEqual(state.sent.map(iso), ['2026-03-04'])
    await a11yAudit()
  })

  test('controlled, it shows @value and asks for each change', async function (assert) {
    const state = new State()
    state.value = MARCH_4
    await render(
      <template>
        <PowerCalendar @name="due" @value={{state.value}} @onValueChange={{state.record}} />
      </template>,
    )
    const calendar = new PowerCalendarHarness('due')
    await calendar.select('2026-03-12')
    assert.deepEqual(state.sent.map(iso), ['2026-03-12'])
    assert.deepEqual(calendar.selected, ['2026-03-04'], 'it waits for @value')
    state.value = new Date(2026, 2, 20)
    await rerender()
    assert.deepEqual(calendar.selected, ['2026-03-20'])
    await a11yAudit()
  })

  test('@value works while empty: undefined is controlled too', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PowerCalendar
          @name="due"
          @value={{state.value}}
          @onValueChange={{state.keep}}
          @defaultCenter={{MARCH_1}}
        />
      </template>,
    )
    const calendar = new PowerCalendarHarness('due')
    assert.deepEqual(calendar.selected, [])
    await calendar.select('2026-03-12')
    assert.strictEqual(iso(state.value), '2026-03-12')
    assert.deepEqual(calendar.selected, ['2026-03-12'])
    await a11yAudit()
  })

  test('it opens on the chosen month, else @defaultCenter, else today, and pages with its nav', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PowerCalendar @name="chosen" @defaultValue={{MARCH_4}} @locale="en-US" />
        <PowerCalendar
          @name="centered"
          @defaultCenter={{MARCH_1}}
          @onCenterChange={{state.record}}
          @locale="en-US"
        />
        <PowerCalendar @name="today" @locale="en-US" />
      </template>,
    )
    assert.strictEqual(new PowerCalendarHarness('chosen').month, 'March 2026')
    const centered = new PowerCalendarHarness('centered')
    assert.strictEqual(centered.month, 'March 2026')
    const today = new PowerCalendarHarness('today')
    assert.strictEqual(today.shownMonth, toIsoDate(new Date()).slice(0, 7))
    assert.strictEqual(today.today, toIsoDate(new Date()), 'today is aria-current="date"')
    assert.dom(today.day(today.today!)).hasAttribute('aria-current', 'date')
    assert.dom(today.day(today.today!)!.parentElement).hasAttribute('data-today', 'true')

    await centered.nextMonth()
    assert.strictEqual(centered.month, 'April 2026')
    await centered.previousMonth()
    await centered.previousMonth()
    assert.strictEqual(centered.month, 'February 2026')
    assert.deepEqual(
      state.sent.map(date => iso(date)!.slice(0, 7)),
      ['2026-04', '2026-03', '2026-02'],
    )
    await a11yAudit()
  })

  test('@center controls the month shown', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PowerCalendar @name="due" @center={{state.center}} @onCenterChange={{state.record}} />
      </template>,
    )
    const calendar = new PowerCalendarHarness('due')
    assert.strictEqual(calendar.shownMonth, '2026-03')
    await calendar.nextMonth()
    assert.strictEqual(calendar.shownMonth, '2026-03', 'it waits for @center')
    assert.strictEqual(iso(state.sent[0])!.slice(0, 7), '2026-04')
    state.center = new Date(2026, 6, 1)
    await rerender()
    assert.strictEqual(calendar.shownMonth, '2026-07')
    await a11yAudit()
  })

  test('@minDate, @maxDate and @disabledDates keep days from being chosen', async function (assert) {
    const weekend = ['Sat', 'Sun', '2026-03-18']
    await render(
      <template>
        <PowerCalendar
          @name="due"
          @defaultCenter={{MARCH_1}}
          @minDate="2026-03-03"
          @maxDate={{(newDate 2026 4 20)}}
          @disabledDates={{weekend}}
        />
      </template>,
    )
    const calendar = new PowerCalendarHarness('due')
    assert.true(calendar.isDayDisabled('2026-03-02'), 'before @minDate')
    assert.false(calendar.isDayDisabled('2026-03-03'))
    assert.true(calendar.isDayDisabled('2026-03-07'), 'a Saturday')
    assert.true(calendar.isDayDisabled('2026-03-08'), 'a Sunday')
    assert.true(calendar.isDayDisabled('2026-03-18'), 'an ISO date')
    assert.dom(calendar.day('2026-03-18')!.parentElement).hasAttribute('data-disabled', 'true')
    assert.true(calendar.isPreviousDisabled, "@minDate's month comes first")
    assert.dom(calendar.previousButton).hasAttribute('aria-disabled', 'true')
    await calendar.previousMonth()
    assert.strictEqual(calendar.shownMonth, '2026-03', 'an aria-disabled nav button does nothing')

    await calendar.nextMonth()
    assert.strictEqual(calendar.shownMonth, '2026-04')
    assert.true(calendar.isDayDisabled('2026-04-21'), 'after @maxDate')
    assert.false(calendar.isDayDisabled('2026-04-20'))
    assert.true(calendar.isNextDisabled)
    await a11yAudit()
  })

  test('@disabled lets no day be chosen, and the months still page', async function (assert) {
    const state = new State()
    state.disabled = true
    await render(
      <template>
        <PowerCalendar
          @name="due"
          @disabled={{state.disabled}}
          @defaultCenter={{MARCH_1}}
          @onValueChange={{state.record}}
        />
      </template>,
    )
    const calendar = new PowerCalendarHarness('due')
    assert.dom(calendar.element).hasAttribute('data-disabled', 'true')
    assert.true(calendar.days.every(day => calendar.isDayDisabled(day)))
    assert.strictEqual(calendar.tabStop, undefined)
    await calendar.nextMonth()
    assert.strictEqual(calendar.shownMonth, '2026-04')
    state.disabled = false
    await rerender()
    await calendar.select('2026-04-02')
    assert.deepEqual(state.sent.map(iso), ['2026-04-02'])
    await a11yAudit()
  })

  test('Tab lands on the chosen day, else today, else the first day of the month', async function (assert) {
    const firstEnabled = ['2026-03-01', '2026-03-02']
    await render(
      <template>
        <button type="button">Before</button>
        <PowerCalendar @name="chosen" @defaultValue={{MARCH_4}} />
        <PowerCalendar @name="today" />
        <PowerCalendar @name="first" @defaultCenter={{MARCH_1}} @disabledDates={{firstEnabled}} />
      </template>,
    )
    const chosen = new PowerCalendarHarness('chosen')
    assert.strictEqual(chosen.tabStop, '2026-03-04')
    assert.strictEqual(new PowerCalendarHarness('today').tabStop, toIsoDate(new Date()))
    assert.strictEqual(
      new PowerCalendarHarness('first').tabStop,
      '2026-03-03',
      "the month's first day that can be chosen",
    )
    assert.strictEqual(
      chosen.parts('day').filter(day => day.getAttribute('tabindex') === '0').length,
      1,
      'one tab stop',
    )

    await click('button')
    await tab()
    assert.dom(chosen.previousButton).isFocused()
    await tab()
    await tab()
    assert.strictEqual(chosen.focusedDay, '2026-03-04', 'then the grid, on its tab stop')
    await a11yAudit()
  })

  test("the arrow keys, Home, End, Page Up and Page Down move as WAI-ARIA's grid", async function (assert) {
    await render(
      <template><PowerCalendar @name="due" @defaultValue={{MARCH_4}} @locale="en-US" /></template>,
    )
    const calendar = new PowerCalendarHarness('due')
    await calendar.focusDay('2026-03-04')

    assert.true(await calendar.pressKey('ArrowRight'), 'it handles the key')
    assert.strictEqual(calendar.focusedDay, '2026-03-05')
    assert.strictEqual(calendar.tabStop, '2026-03-05', 'the tab stop follows focus')
    await calendar.pressKey('ArrowLeft')
    await calendar.pressKey('ArrowLeft')
    assert.strictEqual(calendar.focusedDay, '2026-03-03')
    await calendar.pressKey('ArrowDown')
    assert.strictEqual(calendar.focusedDay, '2026-03-10')
    await calendar.pressKey('ArrowUp')
    assert.strictEqual(calendar.focusedDay, '2026-03-03')
    await calendar.pressKey('Home')
    assert.strictEqual(calendar.focusedDay, '2026-03-01', "the week's first day, Sunday in en-US")
    await calendar.pressKey('End')
    assert.strictEqual(calendar.focusedDay, '2026-03-07')

    await calendar.pressKey('PageDown')
    assert.strictEqual(calendar.month, 'April 2026')
    assert.strictEqual(calendar.focusedDay, '2026-04-07', 'the same day of the next month')
    await calendar.pressKey('PageUp')
    await calendar.pressKey('PageUp')
    assert.strictEqual(calendar.focusedDay, '2026-02-07')
    await calendar.pressKey('PageDown', { shiftKey: true })
    assert.strictEqual(calendar.month, 'February 2027', 'with Shift, a year')
    assert.strictEqual(calendar.focusedDay, '2027-02-07')

    // Past the month's end, the next month comes into view.
    await calendar.focusDay('2027-02-27')
    await calendar.pressKey('ArrowDown')
    assert.strictEqual(calendar.month, 'March 2027')
    assert.strictEqual(calendar.focusedDay, '2027-03-06')
    await a11yAudit()
  })

  test('the keyboard passes over days that cannot be chosen', async function (assert) {
    const blocked = ['2026-03-05', '2026-03-06', '2026-03-11']
    await render(
      <template>
        <PowerCalendar
          @name="due"
          @defaultValue={{MARCH_4}}
          @disabledDates={{blocked}}
          @maxDate="2026-03-31"
        />
      </template>,
    )
    const calendar = new PowerCalendarHarness('due')
    await calendar.focusDay('2026-03-04')
    await calendar.pressKey('ArrowRight')
    assert.strictEqual(calendar.focusedDay, '2026-03-07')
    await calendar.focusDay('2026-03-04')
    await calendar.pressKey('ArrowDown')
    assert.strictEqual(calendar.focusedDay, '2026-03-18', 'a week on from the 11th, too')
    await calendar.focusDay('2026-03-30')
    await calendar.pressKey('ArrowDown')
    assert.strictEqual(calendar.focusedDay, '2026-03-30', 'nothing past @maxDate: focus stays')
    assert.strictEqual(calendar.month, 'March 2026')
    await a11yAudit()
  })

  test('right to left, the arrow keys flip, and the nav and chevrons mirror', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <PowerCalendar @name="due" @defaultValue={{MARCH_4}} @locale="ar" />
        </DirectionProvider>
      </template>,
    )
    const calendar = new PowerCalendarHarness('due')
    await calendar.focusDay('2026-03-04')
    await calendar.pressKey('ArrowLeft')
    assert.strictEqual(calendar.focusedDay, '2026-03-05', 'left is forward, right to left')
    await calendar.pressKey('ArrowRight')
    assert.strictEqual(calendar.focusedDay, '2026-03-04')

    const previous = calendar.previousButton.getBoundingClientRect()
    const next = calendar.nextButton.getBoundingClientRect()
    assert.true(previous.left > next.left, 'the previous month is on the right')
    assert.strictEqual(
      getComputedStyle(calendar.previousButton.querySelector('svg')!).rotate,
      '180deg',
      'its chevron points right',
    )
    const days = calendar.parts('week')[1]!.querySelectorAll('button')
    assert.true(
      days[0]!.getBoundingClientRect().left > days[6]!.getBoundingClientRect().left,
      'the week runs right to left',
    )
    assert.true(calendar.month.length > 0)
    assert.notEqual(calendar.month, 'March 2026', 'the caption is in the locale')
    await a11yAudit()
  })

  test('@locale, @startOfWeek, @weekdayFormat and @showDaysAround', async function (assert) {
    await render(
      <template>
        <PowerCalendar @name="fr" @defaultValue={{MARCH_4}} @locale="fr-FR" />
        <PowerCalendar
          @name="monday"
          @defaultValue={{MARCH_4}}
          @locale="en-US"
          @startOfWeek={{1}}
          @weekdayFormat="min"
          @showDaysAround={{false}}
        />
      </template>,
    )
    const fr = new PowerCalendarHarness('fr')
    assert.strictEqual(fr.month, 'mars 2026')
    assert.strictEqual(fr.dayLabel('2026-03-04'), 'mercredi 4 mars 2026')
    assert.strictEqual(fr.weekdayNames[0], 'lundi', "France's week starts on Monday")

    const monday = new PowerCalendarHarness('monday')
    assert.deepEqual(monday.weekdays, ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
    assert.strictEqual(monday.weekdayNames[0], 'Monday')
    const hidden = monday.element.querySelector('[data-hidden]')!
    assert.strictEqual(getComputedStyle(hidden).visibility, 'hidden', 'no days around the month')
    assert.strictEqual(monday.anyDay('2026-02-28'), null)
    await a11yAudit()
  })

  test('@label and the nav labels are arguments', async function (assert) {
    await render(
      <template>
        <PowerCalendar
          @name="due"
          @label="Due date"
          @previousMonthLabel="Mois précédent"
          @nextMonthLabel="Mois suivant"
        />
      </template>,
    )
    const calendar = new PowerCalendarHarness('due')
    assert.strictEqual(calendar.label, 'Due date')
    assert.dom(calendar.previousButton).hasAttribute('aria-label', 'Mois précédent')
    assert.dom(calendar.nextButton).hasAttribute('aria-label', 'Mois suivant')
    await a11yAudit()
  })

  module('PowerCalendarRange', function () {
    test('the first press starts a range, the second ends it, in either order', async function (assert) {
      const state = new State()
      await render(
        <template>
          <PowerCalendarRange
            @name="stay"
            @defaultCenter={{MARCH_1}}
            @onValueChange={{state.record}}
            @locale="en-US"
          />
        </template>,
      )
      const calendar = new PowerCalendarHarness('stay')
      assert.strictEqual(calendar.kind, 'range')
      assert.strictEqual(calendar.label, 'Choose date range')
      assert.dom(calendar.grid).hasAttribute('aria-multiselectable', 'true')
      assert.dom(calendar.element).hasAttribute('data-test-jn', 'power-calendar-range')

      await calendar.select('2026-03-12')
      assert.deepEqual(calendar.selected, ['2026-03-12'])
      assert.dom(calendar.day('2026-03-12')).hasAttribute('data-range-start', 'true')
      await calendar.select('2026-03-09')
      assert.deepEqual(calendar.selected, ['2026-03-09', '2026-03-10', '2026-03-11', '2026-03-12'])
      assert.deepEqual(state.sent.map(isoRange), [
        { from: '2026-03-12', to: undefined },
        { from: '2026-03-09', to: '2026-03-12' },
      ])

      const start = calendar.day('2026-03-09')!
      const middle = calendar.day('2026-03-10')!
      const end = calendar.day('2026-03-12')!
      assert.dom(start).hasAttribute('data-range-start', 'true')
      assert.dom(start).hasAttribute('data-selected-single', 'false')
      assert.dom(start.parentElement).hasAttribute('data-range-start', 'true')
      assert.dom(middle).hasAttribute('data-range-middle', 'true')
      assert.dom(middle.parentElement).hasAttribute('data-range-middle', 'true')
      assert.dom(end).hasAttribute('data-range-end', 'true')
      assert.dom(end.parentElement).hasAttribute('data-range-end', 'true')

      await calendar.select('2026-03-20')
      assert.deepEqual(calendar.selected, ['2026-03-20'], 'a third press starts again')
      await a11yAudit()
    })

    test('the ends are filled and the days between them shaded, as one band', async function (assert) {
      const range = { from: new Date(2026, 2, 9), to: new Date(2026, 2, 12) }
      await render(<template><PowerCalendarRange @name="stay" @defaultValue={{range}} /></template>)
      const calendar = new PowerCalendarHarness('stay')
      const start = getComputedStyle(calendar.day('2026-03-09')!)
      const middle = getComputedStyle(calendar.day('2026-03-10')!)
      const outside = getComputedStyle(calendar.day('2026-03-13')!)
      const end = getComputedStyle(calendar.day('2026-03-12')!)
      assert.strictEqual(start.backgroundColor, end.backgroundColor, 'both ends in --primary')
      assert.notEqual(start.backgroundColor, middle.backgroundColor)
      assert.notEqual(middle.backgroundColor, outside.backgroundColor, 'the middle in --muted')
      const startCell = getComputedStyle(calendar.day('2026-03-09')!.parentElement!)
      assert.strictEqual(
        startCell.backgroundColor,
        middle.backgroundColor,
        "the start's cell is shaded too, joining the band",
      )
      assert.strictEqual(middle.borderRadius, '0px', 'the middle is square')
      await a11yAudit()
    })

    test('controlled; @minRange and @maxRange limit the end', async function (assert) {
      const state = new State()
      state.range = { from: new Date(2026, 2, 10), to: undefined }
      await render(
        <template>
          <PowerCalendarRange
            @name="stay"
            @value={{state.range}}
            @onValueChange={{state.keepRange}}
            @minRange={{2}}
            @maxRange={{5}}
          />
        </template>,
      )
      const calendar = new PowerCalendarHarness('stay')
      assert.true(calendar.isDayDisabled('2026-03-11'), 'too close to the start')
      assert.false(calendar.isDayDisabled('2026-03-12'))
      assert.false(calendar.isDayDisabled('2026-03-15'))
      assert.true(calendar.isDayDisabled('2026-03-16'), 'too far from it')
      await calendar.select('2026-03-14')
      assert.deepEqual(isoRange(state.range), { from: '2026-03-10', to: '2026-03-14' })
      assert.false(calendar.isDayDisabled('2026-03-11'), 'with both ends, any day starts again')
      await a11yAudit()
    })

    test('@proximitySelection moves the nearer end', async function (assert) {
      const state = new State()
      state.range = { from: new Date(2026, 2, 10), to: new Date(2026, 2, 20) }
      await render(
        <template>
          <PowerCalendarRange
            @name="stay"
            @value={{state.range}}
            @onValueChange={{state.keepRange}}
            @proximitySelection={{true}}
          />
        </template>,
      )
      const calendar = new PowerCalendarHarness('stay')
      await calendar.select('2026-03-18')
      assert.deepEqual(isoRange(state.range), { from: '2026-03-10', to: '2026-03-18' })
      await calendar.select('2026-03-08')
      assert.deepEqual(isoRange(state.range), { from: '2026-03-08', to: '2026-03-18' })
      await a11yAudit()
    })
  })

  module('PowerCalendarMultiple', function () {
    test('each press adds a day or removes one; @maxLength caps them', async function (assert) {
      const state = new State()
      await render(
        <template>
          <PowerCalendarMultiple
            @name="days"
            @value={{state.days}}
            @onValueChange={{state.keepDays}}
            @defaultCenter={{MARCH_1}}
            @maxLength={{2}}
          />
        </template>,
      )
      const calendar = new PowerCalendarHarness('days')
      assert.strictEqual(calendar.kind, 'multiple')
      assert.strictEqual(calendar.label, 'Choose dates')
      assert.dom(calendar.grid).hasAttribute('aria-multiselectable', 'true')

      await calendar.selectDays('2026-03-03', '2026-03-12')
      assert.deepEqual(calendar.selected, ['2026-03-03', '2026-03-12'])
      assert.deepEqual(state.days.map(iso), ['2026-03-03', '2026-03-12'])
      assert.dom(calendar.day('2026-03-12')).hasAttribute('data-selected-single', 'true')
      assert.true(calendar.isDayDisabled('2026-03-20'), 'with two chosen, no third')
      assert.false(calendar.isDayDisabled('2026-03-03'), 'a chosen day can still be removed')

      await calendar.select('2026-03-03')
      assert.deepEqual(calendar.selected, ['2026-03-12'])
      assert.false(calendar.isDayDisabled('2026-03-20'))
      await a11yAudit()
    })

    test('uncontrolled, from @defaultValue', async function (assert) {
      const chosen = [new Date(2026, 2, 2), new Date(2026, 2, 9)]
      await render(
        <template><PowerCalendarMultiple @name="days" @defaultValue={{chosen}} /></template>,
      )
      const calendar = new PowerCalendarHarness('days')
      assert.deepEqual(calendar.selected, ['2026-03-02', '2026-03-09'])
      await calendar.select('2026-03-16')
      assert.deepEqual(calendar.selected, ['2026-03-02', '2026-03-09', '2026-03-16'])
      await a11yAudit()
    })
  })

  test('the harness finds every kind, and says when a day is missing', async function (assert) {
    await render(
      <template>
        <PowerCalendar @defaultValue={{MARCH_4}} />
        <PowerCalendarRange @defaultCenter={{MARCH_1}} />
        <PowerCalendarMultiple @defaultCenter={{MARCH_1}} />
      </template>,
    )
    const kinds = PowerCalendarHarness.findAll().map(calendar => calendar.kind)
    assert.deepEqual(kinds, ['single', 'range', 'multiple'])
    const [single] = PowerCalendarHarness.findAll()
    assert.throws(() => single!.isDayDisabled('2026-04-01'), /no day 2026-04-01/)
    await a11yAudit()
  })

  test('the days list (array helper)', async function (assert) {
    await render(
      <template>
        <PowerCalendar @name="due" @defaultCenter={{MARCH_1}} @disabledDates={{array "Sun"}} />
      </template>,
    )
    assert.true(new PowerCalendarHarness('due').isDayDisabled('2026-03-01'))
    await a11yAudit()
  })
})

function newDate(year: number, month: number, day: number): Date {
  return new Date(year, month - 1, day)
}
