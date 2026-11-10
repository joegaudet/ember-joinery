import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, rerender, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  isoDate,
  parseIsoDate,
  type CalendarValue,
  type DateRange,
} from '@ember-joinery/primitives/calendar'
import { Calendar, Card } from '@ember-joinery/ember'
import { CalendarHarness, tab } from '@ember-joinery/test-support'

const day = parseIsoDate
// Thursday 15 January 2026; the month's grid runs from Sunday 28 December to Saturday 31 January.
const TODAY = day('2026-01-15')

/** A record of each `@onValueChange`, and the value it last heard. */
class Changes {
  @tracked value: CalendarValue = undefined
  calls: CalendarValue[] = []
  record = (value: CalendarValue) => {
    this.calls.push(value)
    this.value = value
  }
}

function isos(
  value: CalendarValue,
): string | string[] | { from?: string; to?: string } | undefined {
  if (value === undefined) return undefined
  if (value instanceof Date) return isoDate(value)
  if (Array.isArray(value)) return value.map(isoDate)
  const range = value as DateRange
  return {
    from: range.from ? isoDate(range.from) : undefined,
    to: range.to ? isoDate(range.to) : undefined,
  }
}

const px = (value: string) => Number.parseFloat(value)

/** Ends the transitions an element is running (a Button's `transition-all`), to read where they go. */
function finishTransitions(element: Element): void {
  for (const animation of element.getAnimations()) animation.finish()
}

module('Integration | components | calendar', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's markup: classes, slots and data attributes", async function (assert) {
    await render(
      <template>
        <Calendar @mode="single" @today={{TODAY}} @name="plain" class="rounded-lg border" />
      </template>,
    )
    const calendar = new CalendarHarness('plain')
    assert
      .dom(calendar.element)
      .hasClass('jn-calendar')
      .hasClass('group/calendar')
      .hasClass('rdp-root')
      .hasClass('rounded-lg', 'your class goes on the root')
      .hasAttribute('data-slot', 'calendar')
      .hasAttribute('data-mode', 'single')
      .doesNotHaveAttribute('data-multiple-months')
    assert.strictEqual(calendar.mode, 'single')
    assert.strictEqual(calendar.caption, 'January 2026')
    assert.deepEqual(calendar.months, ['2026-01-01'])
    assert.deepEqual(calendar.weekdays, ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'])
    assert.deepEqual(calendar.weekdayLabels.slice(0, 2), ['Sunday', 'Monday'])
    assert.strictEqual(calendar.cells.length, 35, 'five whole weeks')
    assert.true(calendar.isOutside('2025-12-28'), 'outside days are shown, as upstream sets')
    assert.dom(calendar.cell('2025-12-28')).hasClass('rdp-outside')

    const cell = calendar.cell('2026-01-15')
    assert
      .dom(cell)
      .hasClass('group/day')
      .hasClass('rdp-day')
      .hasClass('rdp-today')
      .hasAttribute('role', 'gridcell')
      .hasAttribute('data-day', '2026-01-15')
      .hasAttribute('data-today', 'true')
    assert
      .dom(calendar.button('2026-01-15'))
      .hasClass('jn-button')
      .hasClass('jn-button-variant-ghost')
      .hasClass('jn-button-size-icon')
      .hasClass('jn-calendar-day-button')
      .hasAttribute('data-slot', 'button')
      .hasAttribute('data-size', 'icon')
      .hasAttribute('data-selected-single', 'false')
      .hasAttribute('data-range-start', 'false')
      .hasAttribute('data-day', TODAY.toLocaleDateString('en-US'))
      .hasAttribute('aria-label', 'Today, Thursday, January 15, 2026')
      .hasText('15')
    assert
      .dom(calendar.previousButton)
      .hasClass('jn-button-variant-ghost')
      .hasClass('jn-button-size-default')
      .hasClass('rdp-button_previous')
      .hasAttribute('aria-label', 'Go to the Previous Month')
    assert.dom(calendar.nextButton).hasAttribute('aria-label', 'Go to the Next Month')
    assert.dom('svg', calendar.previousButton).hasClass('jn-rtl-flip').hasClass('rdp-chevron')
    assert
      .dom(calendar.grids[0])
      .hasAttribute('aria-label', 'January 2026')
      .hasAttribute('aria-multiselectable', 'false')
    assert.dom('thead', calendar.element).hasAttribute('aria-hidden', 'true')
    await a11yAudit()
  })

  test('its style sheet sizes the cells from --cell-size, without Tailwind', async function (assert) {
    await render(
      <template>
        <Calendar @mode="single" @today={{TODAY}} @defaultValue={{day "2026-01-12"}} />
      </template>,
    )
    const calendar = new CalendarHarness()
    const root = getComputedStyle(calendar.element)
    assert.strictEqual(root.paddingTop, '8px', "Nova's p-2")
    const parent = calendar.element.parentElement!.offsetWidth
    assert.true(calendar.element.offsetWidth < parent, 'w-fit')
    const button = calendar.button('2026-01-13')
    assert.strictEqual(button.offsetWidth, 28, 'min-w-(--cell-size): 28px in Nova')
    assert.strictEqual(button.offsetHeight, 28, 'aspect-square')
    const months = getComputedStyle(calendar.element.querySelector('.rdp-months')!)
    assert.strictEqual(months.display, 'flex')
    assert.strictEqual(
      getComputedStyle(calendar.element.querySelector('.rdp-nav')!).position,
      'absolute',
    )
    const weekday = getComputedStyle(calendar.parts('weekday')[0]!)
    assert.strictEqual(weekday.fontSize, '12.8px', 'text-[0.8rem]')
    assert.strictEqual(weekday.fontWeight, '400')
    const selected = getComputedStyle(calendar.button('2026-01-12'))
    const today = getComputedStyle(calendar.cell('2026-01-15'))
    assert.notStrictEqual(selected.backgroundColor, 'rgba(0, 0, 0, 0)', 'a selected day is filled')
    assert.notStrictEqual(today.backgroundColor, 'rgba(0, 0, 0, 0)', "today's cell is muted")
    assert.strictEqual(
      getComputedStyle(calendar.cell('2025-12-28')).color,
      getComputedStyle(calendar.parts('weekday')[0]!).color,
      'outside days are muted',
    )
    await a11yAudit()
  })

  module('single', function () {
    test('uncontrolled: a press selects a day, and another press on it lets it go', async function (assert) {
      const changes = new Changes()
      await render(
        <template>
          <Calendar
            @mode="single"
            @today={{TODAY}}
            @defaultValue={{day "2026-01-05"}}
            @onValueChange={{changes.record}}
          />
        </template>,
      )
      const calendar = new CalendarHarness()
      assert.deepEqual(calendar.selectedDays, ['2026-01-05'])
      await calendar.select('2026-01-20')
      assert.deepEqual(calendar.selectedDays, ['2026-01-20'])
      assert.strictEqual(isos(changes.value), '2026-01-20')
      assert.dom(calendar.button('2026-01-20')).hasAttribute('data-selected-single', 'true')
      assert.strictEqual(calendar.dayLabel('2026-01-20'), 'Tuesday, January 20, 2026, selected')
      await calendar.select('2026-01-20')
      assert.deepEqual(calendar.selectedDays, [])
      assert.strictEqual(changes.value, undefined)
      await a11yAudit()
    })

    test('controlled: it shows @value, even unset, and asks @onValueChange for each change', async function (assert) {
      class State {
        @tracked value: Date | undefined = undefined
        calls: CalendarValue[] = []
        change = (value: CalendarValue) => this.calls.push(value)
      }
      const state = new State()
      await render(
        <template>
          <Calendar
            @mode="single"
            @today={{TODAY}}
            @value={{state.value}}
            @onValueChange={{state.change}}
          />
        </template>,
      )
      const calendar = new CalendarHarness()
      await calendar.select('2026-01-08')
      assert.deepEqual(calendar.selectedDays, [], 'nothing changes until @value does')
      assert.deepEqual(state.calls.map(isos), ['2026-01-08'])
      state.value = day('2026-01-09')
      await rerender()
      assert.deepEqual(calendar.selectedDays, ['2026-01-09'])
      state.value = undefined
      await rerender()
      assert.deepEqual(calendar.selectedDays, [], 'cleared by the caller')
      await a11yAudit()
    })

    test('@required keeps the selected day when it is pressed again', async function (assert) {
      await render(
        <template>
          <Calendar
            @mode="single"
            @required={{true}}
            @today={{TODAY}}
            @defaultValue={{day "2026-01-05"}}
          />
        </template>,
      )
      const calendar = new CalendarHarness()
      assert.dom(calendar.element).hasAttribute('data-required', 'true')
      await calendar.select('2026-01-05')
      assert.deepEqual(calendar.selectedDays, ['2026-01-05'])
      await a11yAudit()
    })

    test('without @mode the days are text, named for assistive technology', async function (assert) {
      await render(<template><Calendar @today={{TODAY}} /></template>)
      const calendar = new CalendarHarness()
      assert.dom('button[data-test-jn-part="day-button"]', calendar.element).doesNotExist()
      assert.strictEqual(calendar.dayLabel('2026-01-15'), 'Today, Thursday, January 15, 2026')
      assert.strictEqual(calendar.dayText('2026-01-16'), '16')
      await a11yAudit()
    })
  })

  module('multiple', function () {
    test('presses add and remove days; @max starts again, @min keeps the last', async function (assert) {
      const changes = new Changes()
      await render(
        <template>
          <Calendar
            @mode="multiple"
            @today={{TODAY}}
            @min={{1}}
            @max={{2}}
            @value={{changes.value}}
            @onValueChange={{changes.record}}
            @name="multi"
          />
        </template>,
      )
      const calendar = new CalendarHarness('multi')
      assert.dom(calendar.grids[0]).hasAttribute('aria-multiselectable', 'true')
      await calendar.selectAll('2026-01-05', '2026-01-07')
      assert.deepEqual(calendar.selectedDays, ['2026-01-05', '2026-01-07'])
      await calendar.select('2026-01-09')
      assert.deepEqual(calendar.selectedDays, ['2026-01-09'], 'past @max, a press starts again')
      await calendar.select('2026-01-09')
      assert.deepEqual(calendar.selectedDays, ['2026-01-09'], '@min keeps it')
      await calendar.select('2026-01-10')
      await calendar.select('2026-01-09')
      assert.deepEqual(calendar.selectedDays, ['2026-01-10'])
      assert.deepEqual(isos(changes.value), ['2026-01-10'])
      await a11yAudit()
    })
  })

  module('range', function () {
    test('two presses make a range, marked start, middle and end', async function (assert) {
      const changes = new Changes()
      await render(
        <template>
          <Calendar
            @mode="range"
            @today={{TODAY}}
            @value={{changes.value}}
            @onValueChange={{changes.record}}
          />
        </template>,
      )
      const calendar = new CalendarHarness()
      await calendar.select('2026-01-12')
      assert.deepEqual(isos(changes.value), { from: '2026-01-12', to: '2026-01-12' })
      await calendar.select('2026-01-16')
      assert.deepEqual(isos(changes.value), { from: '2026-01-12', to: '2026-01-16' })
      assert.deepEqual(calendar.selectedDays, [
        '2026-01-12',
        '2026-01-13',
        '2026-01-14',
        '2026-01-15',
        '2026-01-16',
      ])
      assert.strictEqual(calendar.rangePosition('2026-01-12'), 'start')
      assert.strictEqual(calendar.rangePosition('2026-01-14'), 'middle')
      assert.strictEqual(calendar.rangePosition('2026-01-16'), 'end')
      assert.dom(calendar.cell('2026-01-12')).hasClass('rdp-range_start')
      assert.dom(calendar.cell('2026-01-14')).hasClass('rdp-range_middle')
      const start = getComputedStyle(calendar.cell('2026-01-12'), '::after')
      assert.strictEqual(start.position, 'absolute', "the start's cell reaches toward the next")
      finishTransitions(calendar.button('2026-01-14'))
      const middle = getComputedStyle(calendar.button('2026-01-14'))
      assert.strictEqual(middle.borderTopLeftRadius, '0px', 'rounded-none in the middle')
      await calendar.select('2026-01-05')
      assert.deepEqual(
        isos(changes.value),
        { from: '2026-01-05', to: '2026-01-16' },
        'an earlier press moves the start',
      )
      await a11yAudit()
    })

    test('@excludeDisabled starts again when a range would cross a disabled day', async function (assert) {
      const disabled = [day('2026-01-14')]
      await render(
        <template>
          <Calendar
            @mode="range"
            @today={{TODAY}}
            @disabled={{disabled}}
            @excludeDisabled={{true}}
          />
        </template>,
      )
      const calendar = new CalendarHarness()
      await calendar.selectAll('2026-01-12', '2026-01-16')
      assert.deepEqual(calendar.selectedDays, ['2026-01-16'])
      await a11yAudit()
    })
  })

  test('@disabled and @hidden take matchers; a disabled day is a disabled button', async function (assert) {
    const isWeekend = (date: Date) => date.getDay() === 0 || date.getDay() === 6
    const hidden = { before: day('2026-01-04') }
    await render(
      <template>
        <Calendar @mode="single" @today={{TODAY}} @disabled={{isWeekend}} @hidden={{hidden}} />
      </template>,
    )
    const calendar = new CalendarHarness()
    assert.true(calendar.isDisabled('2026-01-10'))
    assert.dom(calendar.button('2026-01-10')).isDisabled()
    assert.dom(calendar.cell('2026-01-10')).hasClass('rdp-disabled')
    assert.false(calendar.isDisabled('2026-01-12'))
    assert.true(calendar.isHidden('2026-01-02'))
    assert.dom('button', calendar.cell('2026-01-02')).doesNotExist()
    assert.strictEqual(getComputedStyle(calendar.cell('2026-01-02')).visibility, 'hidden')
    await a11yAudit()
  })

  test('@onDayClick hears every press; @onValueChange hears the day pressed too', async function (assert) {
    const clicks: string[] = []
    const details: string[] = []
    const onDayClick = (date: Date, modifiers: { selected: boolean }) =>
      clicks.push(`${isoDate(date)} ${modifiers.selected ? 'selected' : 'not selected'}`)
    const onValueChange = (_value: CalendarValue, change: { date: Date }) =>
      details.push(isoDate(change.date))
    await render(
      <template>
        <Calendar
          @mode="single"
          @today={{TODAY}}
          @defaultValue={{day "2026-01-05"}}
          @onDayClick={{onDayClick}}
          @onValueChange={{onValueChange}}
        />
      </template>,
    )
    const calendar = new CalendarHarness()
    await calendar.select('2026-01-05')
    await calendar.select('2026-01-06')
    assert.deepEqual(clicks, ['2026-01-05 selected', '2026-01-06 not selected'])
    assert.deepEqual(details, ['2026-01-05', '2026-01-06'])
    assert.deepEqual(calendar.selected.map(isoDate), ['2026-01-06'])
    assert.deepEqual(calendar.monthLabels, ['January 2026'])
    await a11yAudit()
  })

  test('@hideNavigation, @hideWeekdays and @disableNavigation', async function (assert) {
    await render(
      <template>
        <Calendar
          @mode="single"
          @today={{TODAY}}
          @hideNavigation={{true}}
          @hideWeekdays={{true}}
          @name="bare"
        />
        <Calendar
          @mode="single"
          @today={{TODAY}}
          @captionLayout="dropdown"
          @disableNavigation={{true}}
          @name="fixed"
        />
      </template>,
    )
    const bare = new CalendarHarness('bare')
    assert.strictEqual(bare.queryPart('nav'), null)
    assert.deepEqual(bare.weekdays, [])
    const fixed = new CalendarHarness('fixed')
    assert.false(fixed.canGoNext)
    assert.false(fixed.canGoPrevious)
    assert.dom(fixed.monthDropdown()).isDisabled()
    await fixed.focus('2026-01-31')
    await fixed.press('ArrowRight')
    assert.strictEqual(fixed.caption, 'January 2026', 'the keys stay in the month shown')
    assert.strictEqual(fixed.focusedDay, '2026-01-31')
    await a11yAudit({ rules: { 'landmark-unique': { enabled: false } } })
  })

  test('@modifiers and @modifiersClassNames mark days of your own', async function (assert) {
    const booked = [day('2026-01-20'), day('2026-01-21')]
    await render(
      <template>
        <Calendar
          @mode="single"
          @today={{TODAY}}
          @modifiers={{hash booked=booked}}
          @modifiersClassNames={{hash booked="is-booked"}}
        />
      </template>,
    )
    const calendar = new CalendarHarness()
    assert.dom(calendar.cell('2026-01-20')).hasClass('is-booked')
    assert.dom(calendar.cell('2026-01-22')).doesNotHaveClass('is-booked')
    await a11yAudit()
  })

  module('navigation', function () {
    test('the buttons move a month, and @onMonthChange hears each', async function (assert) {
      const months: string[] = []
      const record = (month: Date) => months.push(isoDate(month))
      await render(
        <template><Calendar @mode="single" @today={{TODAY}} @onMonthChange={{record}} /></template>,
      )
      const calendar = new CalendarHarness()
      await calendar.next()
      assert.strictEqual(calendar.caption, 'February 2026')
      await calendar.previous()
      await calendar.previous()
      assert.strictEqual(calendar.caption, 'December 2025')
      assert.deepEqual(months, ['2026-02-01', '2026-01-01', '2025-12-01'])
      await a11yAudit()
    })

    test('@month controls the month shown', async function (assert) {
      class State {
        @tracked month = day('2026-03-10')
      }
      const state = new State()
      const go = (month: Date) => (state.month = month)
      await render(
        <template>
          <Calendar @mode="single" @today={{TODAY}} @month={{state.month}} @onMonthChange={{go}} />
        </template>,
      )
      const calendar = new CalendarHarness()
      assert.strictEqual(calendar.caption, 'March 2026')
      state.month = day('2026-07-01')
      await rerender()
      assert.strictEqual(calendar.caption, 'July 2026')
      await calendar.next()
      assert.strictEqual(calendar.caption, 'August 2026')
      await a11yAudit()
    })

    test('@startMonth and @endMonth bound it: the buttons are aria-disabled at the ends', async function (assert) {
      const start = day('2025-12-01')
      const end = day('2026-02-01')
      await render(
        <template>
          <Calendar
            @mode="single"
            @today={{TODAY}}
            @defaultMonth={{end}}
            @startMonth={{start}}
            @endMonth={{end}}
          />
        </template>,
      )
      const calendar = new CalendarHarness()
      assert.false(calendar.canGoNext)
      assert
        .dom(calendar.nextButton)
        .hasAttribute('aria-disabled', 'true')
        .hasAttribute('tabindex', '-1')
      assert.strictEqual(
        getComputedStyle(calendar.nextButton).opacity,
        '0.5',
        'aria-disabled:opacity-50',
      )
      await calendar.next()
      assert.strictEqual(calendar.caption, 'February 2026')
      await calendar.previous()
      await calendar.previous()
      assert.false(calendar.canGoPrevious)
      assert.true(calendar.isHidden('2025-11-30'), 'days before the start are hidden')
      await a11yAudit()
    })

    test('@numberOfMonths shows months side by side; @pagedNavigation moves by all of them', async function (assert) {
      await render(
        <template>
          <Calendar
            @mode="range"
            @today={{TODAY}}
            @numberOfMonths={{2}}
            @pagedNavigation={{true}}
          />
        </template>,
      )
      const calendar = new CalendarHarness()
      assert.dom(calendar.element).hasAttribute('data-multiple-months', 'true')
      assert.deepEqual(calendar.captions, ['January 2026', 'February 2026'])
      assert.true(calendar.isOutside('2026-02-01') === false, 'February 1 in its own month')
      await calendar.next()
      assert.deepEqual(calendar.captions, ['March 2026', 'April 2026'])
      await a11yAudit()
    })

    test('the dropdown caption picks a month and a year, a hundred years back by default', async function (assert) {
      const months: string[] = []
      const record = (month: Date) => months.push(isoDate(month))
      await render(
        <template>
          <Calendar
            @mode="single"
            @today={{TODAY}}
            @captionLayout="dropdown"
            @onMonthChange={{record}}
          />
        </template>,
      )
      const calendar = new CalendarHarness()
      assert.strictEqual(calendar.monthOptions().length, 12)
      assert.strictEqual(calendar.monthOptions()[0], 'Jan', "shadcn's short month names")
      assert.strictEqual(calendar.yearOptions()[0], '1926')
      assert.strictEqual(calendar.yearOptions().at(-1), '2026')
      assert
        .dom(calendar.monthDropdown())
        .hasAttribute('aria-label', 'Choose the Month')
        .hasValue('0')
      assert
        .dom(calendar.yearDropdown())
        .hasAttribute('aria-label', 'Choose the Year')
        .hasValue('2026')
      assert.dom('.rdp-dropdown_root .rdp-caption_label', calendar.element).hasText('Jan')
      await calendar.chooseMonth('Mar')
      assert.strictEqual(calendar.caption, 'March 2026', 'the live region reads the new month')
      await calendar.chooseYear(1990)
      assert.strictEqual(calendar.caption, 'March 1990')
      assert.deepEqual(months, ['2026-03-01', '1990-03-01'])
      assert.strictEqual(
        getComputedStyle(calendar.monthDropdown()!).opacity,
        '0',
        'the select is invisible',
      )
      await a11yAudit()
    })

    test('@captionLayout="dropdown-months" shows the year as text', async function (assert) {
      await render(
        <template>
          <Calendar @mode="single" @today={{TODAY}} @captionLayout="dropdown-months" />
        </template>,
      )
      const calendar = new CalendarHarness()
      assert.notStrictEqual(calendar.monthDropdown(), null)
      assert.strictEqual(calendar.yearDropdown(), null)
      assert.dom('.rdp-dropdowns', calendar.element).includesText('2026')
      await a11yAudit()
    })
  })

  module('keyboard', function () {
    test('one day is in the tab order: the selected day, else today', async function (assert) {
      await render(
        <template>
          <button type="button">Before</button>
          <Calendar @mode="single" @today={{TODAY}} @defaultValue={{day "2026-01-20"}} />
        </template>,
      )
      const calendar = new CalendarHarness()
      assert.strictEqual(calendar.tabStop, '2026-01-20')
      await click('button')
      await tab() // the previous button
      await tab() // the next button
      await tab()
      assert.strictEqual(calendar.focusedDay, '2026-01-20')
      await a11yAudit()
    })

    test("the arrow keys, Page Up and Down, Home and End move focus by APG's date grid", async function (assert) {
      await render(<template><Calendar @mode="single" @today={{TODAY}} /></template>)
      const calendar = new CalendarHarness()
      assert.strictEqual(calendar.tabStop, '2026-01-15', 'today')
      await calendar.focus('2026-01-15')
      await calendar.press('ArrowRight')
      assert.strictEqual(calendar.focusedDay, '2026-01-16')
      assert.strictEqual(calendar.tabStop, '2026-01-16', 'the tab stop follows focus')
      await calendar.press('ArrowDown')
      assert.strictEqual(calendar.focusedDay, '2026-01-23')
      await calendar.press('ArrowLeft')
      await calendar.press('ArrowUp')
      assert.strictEqual(calendar.focusedDay, '2026-01-15')
      await calendar.press('Home')
      assert.strictEqual(calendar.focusedDay, '2026-01-11', 'the start of the week')
      await calendar.press('End')
      assert.strictEqual(calendar.focusedDay, '2026-01-17')
      await calendar.press('PageDown')
      assert.strictEqual(
        calendar.focusedDay,
        '2026-02-17',
        'a month on, and the month shown with it',
      )
      assert.strictEqual(calendar.caption, 'February 2026')
      await calendar.press('PageUp', { shiftKey: true })
      assert.strictEqual(calendar.focusedDay, '2025-02-17', 'Shift: a year')
      await calendar.press('ArrowRight', { shiftKey: true })
      assert.strictEqual(calendar.focusedDay, '2025-03-17', 'Shift with an arrow: a month')
      await calendar.press('ArrowDown', { shiftKey: true })
      assert.strictEqual(calendar.focusedDay, '2026-03-17')
      await a11yAudit()
    })

    test('moving across a month edge shows that month, and Enter selects', async function (assert) {
      await render(<template><Calendar @mode="single" @today={{TODAY}} /></template>)
      const calendar = new CalendarHarness()
      await calendar.focus('2026-01-31')
      await calendar.press('ArrowRight')
      assert.strictEqual(calendar.caption, 'February 2026')
      assert.strictEqual(calendar.focusedDay, '2026-02-01')
      calendar.button('2026-02-01').click() // Enter or Space on a button is a click
      await settled()
      assert.deepEqual(calendar.selectedDays, ['2026-02-01'])
      await a11yAudit()
    })

    test('the keys skip disabled days', async function (assert) {
      const disabled = [day('2026-01-16'), day('2026-01-17')]
      await render(
        <template><Calendar @mode="single" @today={{TODAY}} @disabled={{disabled}} /></template>,
      )
      const calendar = new CalendarHarness()
      await calendar.focus('2026-01-15')
      await calendar.press('ArrowRight')
      assert.strictEqual(calendar.focusedDay, '2026-01-18')
      await a11yAudit()
    })

    test('focus leaving and coming back returns to the last day focused', async function (assert) {
      await render(
        <template>
          <Calendar @mode="single" @today={{TODAY}} />
          <button type="button">After</button>
        </template>,
      )
      const calendar = new CalendarHarness()
      await calendar.focus('2026-01-15')
      await calendar.press('ArrowDown')
      await tab()
      assert.strictEqual(calendar.focusedDay, null)
      assert.strictEqual(calendar.tabStop, '2026-01-22')
      await tab({ shift: true })
      assert.strictEqual(calendar.focusedDay, '2026-01-22')
      await a11yAudit()
    })

    test('@autoFocus focuses the tab stop as it renders', async function (assert) {
      await render(
        <template><Calendar @mode="single" @today={{TODAY}} @autoFocus={{true}} /></template>,
      )
      assert.strictEqual(new CalendarHarness().focusedDay, '2026-01-15')
      await a11yAudit()
    })
  })

  module('right to left', function () {
    test('the arrow keys flip, and the chevrons turn', async function (assert) {
      await render(
        <template>
          <DirectionProvider @dir="rtl"><Calendar
              @mode="single"
              @today={{TODAY}}
            /></DirectionProvider>
        </template>,
      )
      const calendar = new CalendarHarness()
      await calendar.focus('2026-01-15')
      await calendar.press('ArrowLeft')
      assert.strictEqual(calendar.focusedDay, '2026-01-16', 'left is later, right to left')
      await calendar.press('ArrowRight')
      assert.strictEqual(calendar.focusedDay, '2026-01-15')
      const chevron = getComputedStyle(calendar.nextButton.querySelector('svg')!)
      assert.strictEqual(chevron.rotate, '180deg')
      const prev = calendar.previousButton.getBoundingClientRect()
      const next = calendar.nextButton.getBoundingClientRect()
      assert.true(prev.left > next.left, 'the previous button is on the right')
      const first = calendar.cell('2026-01-11').getBoundingClientRect()
      const second = calendar.cell('2026-01-12').getBoundingClientRect()
      assert.true(first.left > second.left, 'the week runs from the right')
      await a11yAudit()
    })

    test("a range's start reaches toward its end: leftward, right to left", async function (assert) {
      const range = { from: day('2026-01-12'), to: day('2026-01-14') }
      await render(
        <template>
          <Calendar @mode="range" @dir="rtl" @today={{TODAY}} @defaultValue={{range}} />
        </template>,
      )
      const calendar = new CalendarHarness()
      const start = getComputedStyle(calendar.cell('2026-01-12'), '::after')
      assert.strictEqual(start.left, '0px', 'after:end-0: the left, right to left')
      const end = getComputedStyle(calendar.cell('2026-01-14'), '::after')
      assert.strictEqual(end.right, '0px', 'after:start-0: the right')
      await a11yAudit()
    })
  })

  module('locale', function () {
    test('@locale names the months and days, and starts the week where the locale does', async function (assert) {
      await render(<template><Calendar @mode="single" @today={{TODAY}} @locale="es" /></template>)
      const calendar = new CalendarHarness()
      assert.strictEqual(calendar.caption, 'enero de 2026')
      assert.strictEqual(calendar.weekdayLabels[0], 'lunes', 'Monday first')
      assert.strictEqual(calendar.cells[0]!.getAttribute('data-day'), '2025-12-29')
      await a11yAudit()
    })

    test('@weekStartsOn overrides the locale', async function (assert) {
      await render(
        <template><Calendar @mode="single" @today={{TODAY}} @weekStartsOn={{1}} /></template>,
      )
      assert.strictEqual(new CalendarHarness().weekdays[0], 'Mo')
      await a11yAudit()
    })

    test('@calendar and @numerals show another calendar: Persian, in Persian digits', async function (assert) {
      const today = day('2025-06-12')
      await render(
        <template>
          <Calendar
            @mode="single"
            @today={{today}}
            @locale="fa-IR"
            @calendar="persian"
            @numerals="arabext"
            @dir="rtl"
          />
        </template>,
      )
      const calendar = new CalendarHarness()
      assert.strictEqual(calendar.months[0], '2025-05-22', 'the month starts on 1 Khordad')
      assert.strictEqual(calendar.dayText('2025-05-22'), '۱')
      assert.true(calendar.caption.includes('خرداد'))
      assert.strictEqual(calendar.weekdayLabels[0], 'شنبه', 'Saturday first')
      await calendar.next()
      assert.strictEqual(calendar.months[0], '2025-06-22', '1 Tir')
      await a11yAudit()
    })

    test('@labels and @formatters replace the words', async function (assert) {
      const labels = { labelNext: () => 'Next month', labelPrevious: () => 'Last month' }
      const formatters = { formatCaption: (month: Date) => `Month ${month.getMonth() + 1}` }
      await render(
        <template>
          <Calendar @mode="single" @today={{TODAY}} @labels={{labels}} @formatters={{formatters}} />
        </template>,
      )
      const calendar = new CalendarHarness()
      assert.dom(calendar.nextButton).hasAttribute('aria-label', 'Next month')
      assert.dom(calendar.previousButton).hasAttribute('aria-label', 'Last month')
      assert.strictEqual(calendar.caption, 'Month 1')
      await a11yAudit()
    })
  })

  test('@showWeekNumber adds a column of week numbers', async function (assert) {
    await render(
      <template><Calendar @mode="single" @today={{TODAY}} @showWeekNumber={{true}} /></template>,
    )
    const calendar = new CalendarHarness()
    assert.dom(calendar.element).hasAttribute('data-week-numbers', 'true')
    assert.deepEqual(calendar.weekNumbers, ['01', '02', '03', '04', '05'])
    assert
      .dom(calendar.parts('week-number')[0])
      .hasAttribute('role', 'rowheader')
      .hasAttribute('aria-label', 'Week 1')
    await a11yAudit()
  })

  test('@fixedWeeks always shows six weeks; @showOutsideDays={{false}} hides the rest', async function (assert) {
    await render(
      <template>
        <Calendar @mode="single" @today={{TODAY}} @fixedWeeks={{true}} @name="fixed" />
        <Calendar @mode="single" @today={{TODAY}} @showOutsideDays={{false}} @name="inside" />
      </template>,
    )
    assert.strictEqual(new CalendarHarness('fixed').cells.length, 42)
    const inside = new CalendarHarness('inside')
    assert.true(inside.isHidden('2025-12-28'))
    assert.dom('button', inside.cell('2025-12-28')).doesNotExist()
    await a11yAudit({ rules: { 'landmark-unique': { enabled: false } } })
  })

  test('a <:day> block draws what each day shows', async function (assert) {
    // The button's name starts with the text it shows, as WCAG 2.5.3 asks.
    const labels = {
      labelDayButton: (date: Date) => `${date.getDate()} $100, ${date.toDateString()}`,
    }
    await render(
      <template>
        <Calendar @mode="single" @today={{TODAY}} @labels={{labels}}>
          <:day as |d|>{{d.label}} <span>{{if d.outside "" "$100"}}</span></:day>
        </Calendar>
      </template>,
    )
    const calendar = new CalendarHarness()
    assert.strictEqual(calendar.dayText('2026-01-12'), '12 $100')
    assert.strictEqual(calendar.dayLabel('2026-01-12'), '12 $100, Mon Jan 12 2026')
    const price = getComputedStyle(calendar.button('2026-01-12').querySelector('span')!)
    assert.strictEqual(price.fontSize, '12px', '[&>span]:text-xs')
    assert.strictEqual(price.opacity, '0.7')
    await a11yAudit()
  })

  test('inside a card, its background is the card’s', async function (assert) {
    await render(
      <template>
        <Card as |c|><c.Content><Calendar @mode="single" @today={{TODAY}} /></c.Content></Card>
      </template>,
    )
    const calendar = new CalendarHarness()
    assert.strictEqual(getComputedStyle(calendar.element).backgroundColor, 'rgba(0, 0, 0, 0)')
    assert.true(px(getComputedStyle(calendar.element).paddingTop) > 0)
    await a11yAudit()
  })
})
