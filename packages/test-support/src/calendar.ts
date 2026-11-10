import { click, focus, select as selectOption, settled } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressKey, type KeyModifiers } from './focus.ts'

/** A day, as the harness takes one: a `Date` (its local day) or `yyyy-MM-dd`. */
export type CalendarDayInput = Date | string

function pad(value: number, length = 2): string {
  return String(value).padStart(length, '0')
}

/** The day as `yyyy-MM-dd`, the key a calendar's days carry in `data-test-jn-value`. */
function iso(day: CalendarDayInput): string {
  if (typeof day === 'string') return day
  return `${pad(day.getFullYear(), 4)}-${pad(day.getMonth() + 1)}-${pad(day.getDate())}`
}

/** A `yyyy-MM-dd` key as a date at local midnight. */
function parse(value: string): Date {
  const [year, month, day] = value.split('-').map(Number) as [number, number, number]
  const date = new Date(2000, 0, 1)
  date.setFullYear(year, month - 1, day)
  return date
}

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<Calendar>` from `@ember-joinery/ember` or `@ember-joinery/primitives/calendar`. It
 * reads the state from each day's cell and button (`aria-selected`, `disabled`, `data-today`,
 * `data-outside`) and the grid's ARIA, and acts as a user does: presses on the days, the
 * previous and next buttons and the dropdowns, and the arrow keys on the focused day.
 *
 *   const calendar = new CalendarHarness('booking') // <Calendar @name="booking">
 *   await calendar.select('2026-01-12')
 *   assert.deepEqual(calendar.selectedDays, ['2026-01-12'])
 *   await calendar.press('ArrowRight')
 *   assert.strictEqual(calendar.focusedDay, '2026-01-13')
 *
 * A day is a `Date` or `yyyy-MM-dd`. Where a day shows twice (an outside day of one month is a
 * day of the next one shown), the harness takes the one in its own month.
 */
export class CalendarHarness extends Harness {
  static override component = 'calendar'

  /** Its `@mode` (`single`, `multiple`, `range`), or `null` when its days aren't buttons. */
  get mode(): string | null {
    return this.element.getAttribute('data-mode')
  }

  /** Each month shown: its grid. */
  get grids(): HTMLTableElement[] {
    return this.parts<HTMLTableElement>('grid')
  }

  /** Each month's caption, in order: `January 2026`. */
  get captions(): string[] {
    return this.parts('caption').map(text)
  }

  /** The first month's caption. */
  get caption(): string {
    return this.captions[0] ?? ''
  }

  /** Each month's grid's name (`aria-label`), in order. */
  get monthLabels(): string[] {
    return this.grids.map(grid => grid.getAttribute('aria-label') ?? '')
  }

  /** The first day of each month shown, as `yyyy-MM-dd`, in order. */
  get months(): string[] {
    return this.values('month')
  }

  /** The column headings, as shown (`Su`, `Mo`…). */
  get weekdays(): string[] {
    const first = this.grids[0]
    if (!first) return []
    return this.parts('weekday')
      .filter(cell => first.contains(cell))
      .map(text)
  }

  /** The columns' full names (`Sunday`…), from their `aria-label`. */
  get weekdayLabels(): string[] {
    const first = this.grids[0]
    if (!first) return []
    return this.parts('weekday')
      .filter(cell => first.contains(cell))
      .map(cell => cell.getAttribute('aria-label') ?? '')
  }

  /** The week numbers shown, in order, as shown (`01`). */
  get weekNumbers(): string[] {
    return this.parts('week-number').map(text)
  }

  /** Every day cell (`role="gridcell"`) of every month, in order. */
  get cells(): HTMLElement[] {
    return this.parts('day')
  }

  /**
   * A day's cell: the one in its own month, or else the first showing it. Throws when no month
   * shows it.
   */
  cell(day: CalendarDayInput): HTMLElement {
    const key = iso(day)
    const cells = this.cells.filter(cell => cell.getAttribute('data-test-jn-value') === key)
    const cell = cells.find(found => !found.hasAttribute('data-outside')) ?? cells[0]
    if (!cell) throw new Error(`${this}: no month shown has the day ${key}`)
    return cell
  }

  /** A day's button. Throws when the day has none (it's hidden, or the calendar has no mode). */
  button(day: CalendarDayInput): HTMLButtonElement {
    const button = this.cell(day).querySelector<HTMLButtonElement>(
      '[data-test-jn-part="day-button"]',
    )
    if (!button) throw new Error(`${this}: the day ${iso(day)} has no button`)
    return button
  }

  /** What a day shows, whitespace collapsed. */
  dayText(day: CalendarDayInput): string {
    return text(this.cell(day))
  }

  /** A day's name, as assistive technology reads it: its button's, or its cell's. */
  dayLabel(day: CalendarDayInput): string {
    const cell = this.cell(day)
    const button = cell.querySelector('[data-test-jn-part="day-button"]')
    return (button ?? cell).getAttribute('aria-label') ?? ''
  }

  /** Whether a day is selected (`aria-selected`). */
  isSelected(day: CalendarDayInput): boolean {
    return this.cell(day).getAttribute('aria-selected') === 'true'
  }

  /** Whether a day can't be selected (its button is `disabled`). */
  isDisabled(day: CalendarDayInput): boolean {
    return this.cell(day).hasAttribute('data-disabled')
  }

  /** Whether a day is today (`data-today`). */
  isToday(day: CalendarDayInput): boolean {
    return this.cell(day).hasAttribute('data-today')
  }

  /** Whether a day belongs to a month around the one it's shown in (`data-outside`). */
  isOutside(day: CalendarDayInput): boolean {
    return this.cell(day).hasAttribute('data-outside')
  }

  /** Whether a day's cell is there but hidden (`data-hidden`). */
  isHidden(day: CalendarDayInput): boolean {
    return this.cell(day).hasAttribute('data-hidden')
  }

  /** Where a day is in a selected range: `start`, `middle`, `end`, or `null`. */
  rangePosition(day: CalendarDayInput): 'start' | 'middle' | 'end' | null {
    const button = this.cell(day).querySelector('[data-test-jn-part="day-button"]')
    if (!button) return null
    if (button.getAttribute('data-range-start') === 'true') return 'start'
    if (button.getAttribute('data-range-end') === 'true') return 'end'
    if (button.getAttribute('data-range-middle') === 'true') return 'middle'
    return null
  }

  /** The selected days shown, as `yyyy-MM-dd`, once each, in order. */
  get selectedDays(): string[] {
    const days = this.cells
      .filter(cell => cell.getAttribute('aria-selected') === 'true')
      .map(cell => cell.getAttribute('data-test-jn-value') ?? '')
    return [...new Set(days)].sort()
  }

  /** The selected days shown, as dates. */
  get selected(): Date[] {
    return this.selectedDays.map(parse)
  }

  /** The disabled days shown, as `yyyy-MM-dd`, once each. */
  get disabledDays(): string[] {
    const days = this.cells
      .filter(cell => cell.hasAttribute('data-disabled'))
      .map(cell => cell.getAttribute('data-test-jn-value') ?? '')
    return [...new Set(days)].sort()
  }

  /** The day whose button has focus, as `yyyy-MM-dd`, or `null`. */
  get focusedDay(): string | null {
    const active = this.element.ownerDocument.activeElement
    if (!active || !this.element.contains(active)) return null
    return active.closest('[data-test-jn-part="day"]')?.getAttribute('data-test-jn-value') ?? null
  }

  /** The day in the tab order (the one button with `tabindex="0"`), as `yyyy-MM-dd`, or `null`. */
  get tabStop(): string | null {
    const button = this.parts('day-button').find(found => found.getAttribute('tabindex') === '0')
    return button?.getAttribute('data-test-jn-value') ?? null
  }

  /** The previous-month button. */
  get previousButton(): HTMLButtonElement {
    return this.part<HTMLButtonElement>('previous')
  }

  /** The next-month button. */
  get nextButton(): HTMLButtonElement {
    return this.part<HTMLButtonElement>('next')
  }

  /** Whether the previous button goes anywhere (it isn't `aria-disabled`). */
  get canGoPrevious(): boolean {
    return this.previousButton.getAttribute('aria-disabled') !== 'true'
  }

  /** Whether the next button goes anywhere. */
  get canGoNext(): boolean {
    return this.nextButton.getAttribute('aria-disabled') !== 'true'
  }

  /** Presses the previous-month button. */
  async previous(): Promise<void> {
    await click(this.previousButton)
  }

  /** Presses the next-month button. */
  async next(): Promise<void> {
    await click(this.nextButton)
  }

  /** A month's month dropdown (the first month's by default), or `null` when it has none. */
  monthDropdown(index = 0): HTMLSelectElement | null {
    return this.parts<HTMLSelectElement>('month-dropdown')[index] ?? null
  }

  /** A month's year dropdown, or `null` when it has none. */
  yearDropdown(index = 0): HTMLSelectElement | null {
    return this.parts<HTMLSelectElement>('year-dropdown')[index] ?? null
  }

  /** The options of a month's month dropdown, as shown (`Jan`…). */
  monthOptions(index = 0): string[] {
    return [...(this.monthDropdown(index)?.options ?? [])].map(option => text(option))
  }

  /** The options of a month's year dropdown, as shown. */
  yearOptions(index = 0): string[] {
    return [...(this.yearDropdown(index)?.options ?? [])].map(option => text(option))
  }

  /**
   * Picks a month in a month's month dropdown: its index in the year (0 for the first) or the
   * option's text (`Mar`), as choosing it does.
   */
  async chooseMonth(month: number | string, index = 0): Promise<void> {
    const select = this.monthDropdown(index)
    if (!select) throw new Error(`${this}: month ${index + 1} has no month dropdown`)
    const option =
      typeof month === 'number'
        ? select.options[month]
        : [...select.options].find(found => text(found) === month)
    if (!option) throw new Error(`${this}: the month dropdown has no option ${month}`)
    await selectOption(select, option.value)
  }

  /** Picks a year in a month's year dropdown, by its number or its text. */
  async chooseYear(year: number | string, index = 0): Promise<void> {
    const select = this.yearDropdown(index)
    if (!select) throw new Error(`${this}: month ${index + 1} has no year dropdown`)
    const option = [...select.options].find(
      found => found.value === String(year) || text(found) === String(year),
    )
    if (!option) throw new Error(`${this}: the year dropdown has no option ${year}`)
    await selectOption(select, option.value)
  }

  /** Presses a day's button, as a click selects it (or lets it go). */
  async select(day: CalendarDayInput): Promise<void> {
    await click(this.button(day))
  }

  /** Presses each day in turn: the ends of a range, or several days. */
  async selectAll(...days: CalendarDayInput[]): Promise<void> {
    for (const day of days) await this.select(day)
  }

  /** Moves focus to a day's button. */
  async focus(day: CalendarDayInput): Promise<void> {
    await focus(this.button(day))
  }

  /**
   * Presses a key on the focused day (focusing the tab stop first when no day has focus):
   * the arrow keys, `PageUp`, `PageDown`, `Home` and `End`, with `shiftKey` for months and
   * years.
   */
  async press(key: string, modifiers: KeyModifiers = {}): Promise<void> {
    if (this.focusedDay === null) {
      const stop = this.tabStop
      if (!stop) throw new Error(`${this}: no day can take focus`)
      await this.focus(stop)
    }
    await pressKey(key, modifiers)
    await settled()
  }
}
