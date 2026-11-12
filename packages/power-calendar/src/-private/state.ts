import { tracked } from '@glimmer/tracking'
import { toDate } from '../dates.ts'

/**
 * A value the caller controls by passing it at all, or the component keeps for itself: as
 * react-day-picker's `selected` and `month`, a calendar is controlled once `@value` (or
 * `@center`) is passed, even as `undefined`, so `@value={{this.date}}` works while the date is
 * still empty. Either way `onChange` hears every change.
 */
export class OwnedValue<T> {
  readonly #controlled: () => boolean
  readonly #arg: () => T
  readonly #onChange: (value: T) => void
  @tracked private own: T

  constructor(options: {
    controlled: () => boolean
    value: () => T
    initial: T
    onChange: (value: T) => void
  }) {
    this.#controlled = options.controlled
    this.#arg = options.value
    this.#onChange = options.onChange
    this.own = options.initial
  }

  get isControlled(): boolean {
    return this.#controlled()
  }

  get value(): T {
    return this.#controlled() ? this.#arg() : this.own
  }

  set(value: T): void {
    if (!this.#controlled()) this.own = value
    this.#onChange(value)
  }
}

/** The arguments every calendar takes, besides its value. */
export interface CalendarOptions {
  /** A BCP 47 locale for the month's name, the weekdays and each day's name. Default: the app's translator's, or the browser's. */
  locale?: string
  /** The first day that can be chosen: a `Date` or `YYYY-MM-DD`. The months before it can't be shown. */
  minDate?: Date | string
  /** The last day that can be chosen: a `Date` or `YYYY-MM-DD`. The months after it can't be shown. */
  maxDate?: Date | string
  /** Days that can't be chosen: `Date`s, `YYYY-MM-DD` strings, or weekdays (`'Sat'`, `'Sun'`). */
  disabledDates?: ReadonlyArray<Date | string>
  /** The first day of the week, 0 (Sunday) to 6. Default: the locale's. */
  startOfWeek?: number
  /** Show the days of the months before and after, to fill the weeks. Default `true`. */
  showDaysAround?: boolean
  /** How the weekdays are written over the columns: `min`, `short` or `long`. Default `short`. */
  weekdayFormat?: 'min' | 'short' | 'long'
  /** The month shown, as any day in it; pass it to control it. Default: the value's, else today's. */
  center?: Date
  /** The month shown first, while you don't control it. */
  defaultCenter?: Date
  /** Called with a day in the month shown, whenever it changes. */
  onCenterChange?: (center: Date) => void
  /** No day can be chosen (the months can still be paged). */
  disabled?: boolean
  /** Its name, for `PowerCalendarHarness` (`data-test-jn-name`). */
  name?: string
  /** The calendar's accessible name. */
  label?: string
  /** The previous-month button's name. Default `Previous month`. */
  previousMonthLabel?: string
  /** The next-month button's name. Default `Next month`. */
  nextMonthLabel?: string
}

const WEEKDAY_NAMES = new Set(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])

/** `@disabledDates` as ember-power-calendar reads them: dates, and weekday names. */
export function normalizeDisabledDates(
  dates: ReadonlyArray<Date | string> | undefined,
): Array<Date | string> | undefined {
  if (!dates) return undefined
  return dates.flatMap((date): Array<Date | string> => {
    if (typeof date === 'string' && WEEKDAY_NAMES.has(date)) return [date]
    const day = toDate(date)
    return day ? [day] : []
  })
}

/** `@startOfWeek` as ember-power-calendar reads it, a string. */
export function startOfWeekArg(startOfWeek: number | undefined): string | undefined {
  return startOfWeek === undefined ? undefined : String(startOfWeek)
}
