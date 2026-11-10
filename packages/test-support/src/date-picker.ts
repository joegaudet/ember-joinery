import { CalendarHarness, type CalendarDayInput } from './calendar.ts'
import { PopoverHarness } from './popover.ts'
import { text } from './-private/overlay.ts'

function pad(value: number, length = 2): string {
  return String(value).padStart(length, '0')
}

/** The day as `yyyy-MM-dd`, the key a calendar's days carry in `data-test-jn-value`. */
function iso(day: CalendarDayInput): string {
  if (typeof day === 'string') return day
  return `${pad(day.getFullYear(), 4)}-${pad(day.getMonth() + 1)}-${pad(day.getDate())}`
}

/** The most months `showMonth()` pages through with the buttons: a hundred years. */
const MAX_STEPS = 1200

/**
 * Drives a date picker: a `<Popover>` whose content holds a `<Calendar>`, as upstream's Date
 * Picker is built (there is no date picker component of its own). It is a `PopoverHarness`, so
 * it opens, closes and reads the popover as that does, and it adds the calendar inside and the
 * trigger's text, and picks a day as a user does: it opens the popover, goes to the day's month
 * (with the month and year dropdowns when the calendar has them, else the previous and next
 * buttons) and presses the day.
 *
 *   const picker = new DatePickerHarness('due') // <Popover @name="due">
 *   assert.strictEqual(picker.text, 'Pick a date')
 *   await picker.pick('2026-03-04')
 *   assert.strictEqual(picker.text, 'March 4th, 2026')
 *   assert.deepEqual(picker.calendar.selectedDays, ['2026-03-04'])
 *
 * A day is a `Date` (its local day) or `yyyy-MM-dd`.
 */
export class DatePickerHarness extends PopoverHarness {
  /** The calendar in the popover's content. It is there only while the popover is open. */
  get calendar(): CalendarHarness {
    return this.child(CalendarHarness)
  }

  /** What the trigger shows, whitespace collapsed: the date as written, or the placeholder. */
  get text(): string {
    return text(this.trigger)
  }

  /** Whether the trigger says no date is picked (`data-empty="true"`, as upstream's demo sets). */
  get isEmpty(): boolean {
    return this.trigger.getAttribute('data-empty') === 'true'
  }

  /** Whether the open calendar shows `day` in its own month (not as an outside day). */
  shows(day: CalendarDayInput): boolean {
    const key = iso(day)
    return this.calendar.cells.some(
      cell => cell.getAttribute('data-test-jn-value') === key && !cell.hasAttribute('data-outside'),
    )
  }

  /**
   * Opens the popover, unless it is open, and moves its calendar to the month holding `day`:
   * with the year and month dropdowns where they have the day's year and month, then the
   * previous and next buttons, a month at a time. Throws when the calendar can't go there (the
   * day is past `@startMonth` or `@endMonth`, or there are no buttons).
   */
  async showMonth(day: CalendarDayInput): Promise<void> {
    await this.open()
    const calendar = this.calendar
    const key = iso(day)
    if (this.shows(key)) return

    const [year, month] = key.split('-').map(Number) as [number, number]
    const years = calendar.yearDropdown()
    if (years && [...years.options].some(option => option.value === String(year))) {
      await calendar.chooseYear(year)
    }
    const months = calendar.monthDropdown()
    const option = months?.options[month - 1]
    const sameYear = !years || calendar.months[0]?.startsWith(`${pad(year, 4)}-`)
    if (option && !option.disabled && sameYear && !this.shows(key)) {
      await calendar.chooseMonth(month - 1)
    }

    for (let steps = 0; !this.shows(key); steps++) {
      const first = calendar.months[0] ?? ''
      const back = key < first
      const button = calendar.queryPart<HTMLButtonElement>(back ? 'previous' : 'next')
      const can = back ? button && calendar.canGoPrevious : button && calendar.canGoNext
      if (!can || steps >= MAX_STEPS) {
        throw new Error(`Joinery harness: ${this}'s calendar can't go to the month of ${key}`)
      }
      await (back ? calendar.previous() : calendar.next())
    }
  }

  /** Opens the popover, goes to the day's month and presses the day. */
  async pick(day: CalendarDayInput): Promise<void> {
    await this.showMonth(day)
    await this.calendar.select(day)
  }

  /**
   * Picks a range: presses `from`, then `to`, going to each one's month (and opening the
   * popover again, if picking `from` closed it).
   */
  async pickRange(from: CalendarDayInput, to: CalendarDayInput): Promise<void> {
    await this.pick(from)
    await this.pick(to)
  }
}
