import { click, focus } from '@ember/test-helpers'
import { Harness, pressKey, type KeyModifiers } from '@ember-joinery/test-support'

/** Which kind of calendar a harness is driving. */
export type PowerCalendarKind = 'single' | 'range' | 'multiple'

const KINDS: Record<string, PowerCalendarKind> = {
  'power-calendar': 'single',
  'power-calendar-range': 'range',
  'power-calendar-multiple': 'multiple',
}

function textOf(element: Element | null | undefined): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `PowerCalendar`, `PowerCalendarRange` or `PowerCalendarMultiple` from
 * `@ember-joinery/power-calendar`. Days are `YYYY-MM-DD` strings; it pages to a day's month
 * with the nav buttons and presses the day, as a user does, and reads the state from the grid's
 * ARIA (`aria-selected`, `aria-current`, `disabled`, the tab stop).
 *
 *   const calendar = new PowerCalendarHarness('due') // <PowerCalendar @name="due">
 *   await calendar.select('2026-03-04')
 *   assert.deepEqual(calendar.selected, ['2026-03-04'])
 *   assert.strictEqual(calendar.month, 'March 2026')
 */
export class PowerCalendarHarness extends Harness {
  static override component = ['power-calendar', 'power-calendar-range', 'power-calendar-multiple']

  /** `single`, `range` or `multiple`. */
  get kind(): PowerCalendarKind {
    return KINDS[this.element.getAttribute('data-test-jn') ?? ''] ?? 'single'
  }

  /** The calendar's accessible name (its `@label`). */
  get label(): string {
    return this.element.getAttribute('aria-label') ?? ''
  }

  /** The grid of days. */
  get grid(): HTMLElement {
    return this.part('grid')
  }

  /** The month shown, as its caption reads: "March 2026". */
  get month(): string {
    return textOf(this.part('caption'))
  }

  /** The month shown, as `YYYY-MM`. */
  get shownMonth(): string {
    const day = this.days[0]
    if (!day) throw new Error(`Joinery harness: ${this} shows no days`)
    return day.slice(0, 7)
  }

  /** The weekday headers, as they read (`Su`, `Mon`…), from the week's first day. */
  get weekdays(): string[] {
    return this.parts('weekday').map(textOf)
  }

  /** The weekdays' full names, the headers' accessible names. */
  get weekdayNames(): string[] {
    return this.parts('weekday').map(header => header.getAttribute('aria-label') ?? '')
  }

  /** The days of the month shown, `YYYY-MM-DD`, in order (not the days around it). */
  get days(): string[] {
    return this.dayButtons().map(day => day.getAttribute('data-date')!)
  }

  /** The days chosen in the month shown, `YYYY-MM-DD`, from `aria-selected`. */
  get selected(): string[] {
    return this.dayButtons()
      .filter(day => day.getAttribute('aria-selected') === 'true')
      .map(day => day.getAttribute('data-date')!)
  }

  /** Today, if it is in the month shown (`aria-current="date"`). */
  get today(): string | undefined {
    return (
      this.dayButtons()
        .find(day => day.getAttribute('aria-current') === 'date')
        ?.getAttribute('data-date') ?? undefined
    )
  }

  /** The day Tab lands on (`tabindex="0"`). */
  get tabStop(): string | undefined {
    return (
      this.parts('day')
        .find(day => day.getAttribute('tabindex') === '0')
        ?.getAttribute('data-date') ?? undefined
    )
  }

  /** The day that has focus, if one does. */
  get focusedDay(): string | undefined {
    const active = document.activeElement
    return this.parts('day').includes(active as HTMLElement)
      ? (active!.getAttribute('data-date') ?? undefined)
      : undefined
  }

  /** The day's button in the month shown, or `null`. Days around the month are left out. */
  day(date: string): HTMLButtonElement | null {
    return (this.dayButtons().find(day => day.getAttribute('data-date') === date) ??
      null) as HTMLButtonElement | null
  }

  /** Any day's button the grid draws, a day around the month included, or `null`. */
  anyDay(date: string): HTMLButtonElement | null {
    return this.queryPart<HTMLButtonElement>('day', date)
  }

  /** The day's accessible name: its full date. */
  dayLabel(date: string): string {
    return this.requireDay(date).getAttribute('aria-label') ?? ''
  }

  /** Whether the day, in the month shown, can't be pressed. */
  isDayDisabled(date: string): boolean {
    return this.requireDay(date).disabled
  }

  /** Whether the day, in the month shown, is chosen. */
  isDaySelected(date: string): boolean {
    return this.requireDay(date).getAttribute('aria-selected') === 'true'
  }

  /** The previous-month button. */
  get previousButton(): HTMLButtonElement {
    return this.part<HTMLButtonElement>('previous')
  }

  /** The next-month button. */
  get nextButton(): HTMLButtonElement {
    return this.part<HTMLButtonElement>('next')
  }

  /** Whether the month before can't be shown (`aria-disabled` on its button). */
  get isPreviousDisabled(): boolean {
    return this.previousButton.getAttribute('aria-disabled') === 'true'
  }

  /** Whether the month after can't be shown. */
  get isNextDisabled(): boolean {
    return this.nextButton.getAttribute('aria-disabled') === 'true'
  }

  async previousMonth(): Promise<void> {
    await click(this.previousButton)
  }

  async nextMonth(): Promise<void> {
    await click(this.nextButton)
  }

  /** Pages with the nav buttons until the month of `date` (`YYYY-MM-DD`) is shown. */
  async goTo(date: string): Promise<void> {
    const wanted = date.slice(0, 7)
    for (let i = 0; i < 1200; i++) {
      const shown = this.shownMonth
      if (shown === wanted) return
      const button = wanted < shown ? this.previousButton : this.nextButton
      if (button.getAttribute('aria-disabled') === 'true') break
      await click(button)
    }
    throw new Error(`Joinery harness: ${this} can't show the month of ${date}`)
  }

  /** Pages to the day's month and presses the day. */
  async select(date: string): Promise<void> {
    await this.goTo(date)
    const day = this.requireDay(date)
    if (day.disabled) throw new Error(`Joinery harness: day ${date} in ${this} is disabled`)
    await click(day)
  }

  /** A range's two ends, pressed in turn. */
  async selectRange(from: string, to: string): Promise<void> {
    await this.select(from)
    await this.select(to)
  }

  /** Several days, pressed in turn (each adds a day, or removes one already chosen). */
  async selectDays(...dates: string[]): Promise<void> {
    for (const date of dates) await this.select(date)
  }

  /** Focuses a day of the month shown. */
  async focusDay(date: string): Promise<void> {
    await focus(this.requireDay(date))
  }

  /** Presses a key on the focused element (a day): `ArrowRight`, `PageDown`, `Enter`. */
  async pressKey(key: string, modifiers: KeyModifiers = {}): Promise<boolean> {
    return pressKey(key, modifiers)
  }

  private dayButtons(): HTMLButtonElement[] {
    return this.parts<HTMLButtonElement>('day').filter(
      day => !day.parentElement?.hasAttribute('data-outside'),
    )
  }

  private requireDay(date: string): HTMLButtonElement {
    const day = this.day(date)
    if (!day) throw new Error(`Joinery harness: no day ${date} in the month ${this} shows`)
    return day
  }
}
