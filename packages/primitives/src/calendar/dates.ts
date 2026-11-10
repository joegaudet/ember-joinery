// Joinery's calendar works on plain `Date`s, with no date library: each day is a `Date` at local
// midnight, as react-day-picker's are (Joinery's Calendar replaces it). Day arithmetic is native.
// Month and year arithmetic goes through a calendar system: the Gregorian one is native too, and
// any other calendar `Intl` knows (Persian, Islamic, Hebrew…) is worked out from `Intl`'s own
// reading of each day, so a Persian calendar needs no Jalali library, as upstream's does.

/** The days of the week, 0 for Sunday to 6 for Saturday, as `Date#getDay()` numbers them. */
export type DayOfWeekNumber = 0 | 1 | 2 | 3 | 4 | 5 | 6

/** A date at local midnight, from its year, month (0 for January) and day. Any year works. */
export function makeDate(year: number, month: number, day: number): Date {
  const date = new Date(2000, 0, 1)
  date.setFullYear(year, month, day)
  return date
}

/** The day `date` falls on, at local midnight. */
export function startOfDay(date: Date): Date {
  return makeDate(date.getFullYear(), date.getMonth(), date.getDate())
}

/**
 * `date` moved by `amount` days (back, when negative), at local midnight: the calendar day, so
 * a daylight-saving change never moves it by an hour.
 */
export function addDays(date: Date, amount: number): Date {
  return makeDate(date.getFullYear(), date.getMonth(), date.getDate() + amount)
}

/** Whether two dates fall on the same day. */
export function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  )
}

/** Compares the days two dates fall on: negative when `a` is earlier, 0 on the same day. */
export function compareDays(a: Date, b: Date): number {
  return (
    a.getFullYear() - b.getFullYear() || a.getMonth() - b.getMonth() || a.getDate() - b.getDate()
  )
}

/** How many days from `b` to `a`, counting calendar days (negative when `a` is earlier). */
export function differenceInDays(a: Date, b: Date): number {
  const utc = (date: Date) => Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())
  return Math.round((utc(a) - utc(b)) / 86_400_000)
}

function pad(value: number, length = 2): string {
  const digits = String(Math.abs(value)).padStart(length, '0')
  return value < 0 ? `-${digits}` : digits
}

/** The day as `yyyy-MM-dd`, in local time: the key Joinery's parts carry in `data-day`. */
export function isoDate(date: Date): string {
  return `${pad(date.getFullYear(), 4)}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

/** The month as `yyyy-MM`, in local time (Gregorian), as upstream's `data-month`. */
export function isoMonth(date: Date): string {
  return `${pad(date.getFullYear(), 4)}-${pad(date.getMonth() + 1)}`
}

/** A `yyyy-MM-dd` string as a date at local midnight (`new Date('2026-01-12')` would be UTC's). */
export function parseIsoDate(value: string): Date {
  const match = /^(-?\d{4,6})-(\d{2})-(\d{2})$/.exec(value)
  if (!match) throw new Error(`Joinery: "${value}" is not a yyyy-MM-dd date`)
  return makeDate(Number(match[1]), Number(match[2]) - 1, Number(match[3]))
}

/** The first day of the week `date` is in, for weeks starting on `weekStartsOn`. */
export function startOfWeek(date: Date, weekStartsOn: DayOfWeekNumber): Date {
  return addDays(date, -((date.getDay() - weekStartsOn + 7) % 7))
}

/** The last day of the week `date` is in. */
export function endOfWeek(date: Date, weekStartsOn: DayOfWeekNumber): Date {
  return addDays(startOfWeek(date, weekStartsOn), 6)
}

// ---------------------------------------------------------------------------------------------
// Calendar systems

/**
 * A calendar's months and years. Each date is still a `Date`; the system says which year, month
 * and day it is in that calendar, and how to move by months and years.
 */
export interface CalendarSystem {
  /** Its `Intl` name: `gregory`, `persian`, `islamic-umalqura`… */
  readonly id: string
  /** The year `date` is in. */
  year(date: Date): number
  /** Which month of its year `date` is in, from 0. */
  month(date: Date): number
  /** Its day of the month, from 1. */
  day(date: Date): number
  /** The first day of the month `date` is in. */
  startOfMonth(date: Date): Date
  /** The last day of the month `date` is in. */
  endOfMonth(date: Date): Date
  /** How many days the month `date` is in has. */
  daysInMonth(date: Date): number
  /** How many months `year` has (13 in a Hebrew leap year). */
  monthsInYear(year: number): number
  /** The first day of month `month` (from 0, at most the year's last) of `year`. */
  monthStart(year: number, month: number): Date
  /** `date` moved by `amount` months, on the same day of the month or its last. */
  addMonths(date: Date, amount: number): Date
  /** `date` moved by `amount` years, in the same month and day, or the nearest there is. */
  addYears(date: Date, amount: number): Date
}

const gregorian: CalendarSystem = {
  id: 'gregory',
  year: date => date.getFullYear(),
  month: date => date.getMonth(),
  day: date => date.getDate(),
  startOfMonth: date => makeDate(date.getFullYear(), date.getMonth(), 1),
  endOfMonth: date => makeDate(date.getFullYear(), date.getMonth() + 1, 0),
  daysInMonth: date => makeDate(date.getFullYear(), date.getMonth() + 1, 0).getDate(),
  monthsInYear: () => 12,
  monthStart: (year, month) => makeDate(year, Math.max(0, Math.min(11, month)), 1),
  addMonths(date, amount) {
    const target = makeDate(date.getFullYear(), date.getMonth() + amount, 1)
    const last = makeDate(target.getFullYear(), target.getMonth() + 1, 0).getDate()
    return makeDate(target.getFullYear(), target.getMonth(), Math.min(date.getDate(), last))
  },
  addYears(date, amount) {
    return gregorian.addMonths(date, amount * 12)
  },
}

/** Calendars whose months and days are the Gregorian ones, with years counted otherwise. */
const GREGORIAN_MONTHS = new Set(['gregory', 'iso8601', 'buddhist', 'japanese', 'roc'])

interface DayParts {
  year: number
  month: string
  day: number
}

/**
 * A calendar `Intl` knows, read from `Intl.DateTimeFormat`'s parts for each day: a month starts
 * on the day numbered 1, and a year when its number changes. Lookups are cached, so the steps
 * it takes stay cheap.
 */
class IntlCalendarSystem implements CalendarSystem {
  readonly id: string
  readonly #format: Intl.DateTimeFormat
  readonly #parts = new Map<string, DayParts>()
  readonly #nextMonth = new Map<string, Date>()
  readonly #monthIndex = new Map<string, number>()
  #yearLength: number | undefined

  constructor(id: string) {
    this.id = id
    this.#format = new Intl.DateTimeFormat(`en-u-ca-${id}-nu-latn`, {
      year: 'numeric',
      month: 'numeric',
      day: 'numeric',
      timeZone: 'UTC',
    })
  }

  #read(date: Date): DayParts {
    const key = isoDate(date)
    let parts = this.#parts.get(key)
    if (parts) return parts
    // The local day, at noon UTC, read in UTC: the same day wherever the browser is.
    const utc = new Date(0)
    utc.setUTCFullYear(date.getFullYear(), date.getMonth(), date.getDate())
    utc.setUTCHours(12)
    let year = 0
    let month = ''
    let day = 0
    for (const part of this.#format.formatToParts(utc)) {
      // `relatedYear` is the Gregorian year of a calendar whose own years cycle (Chinese).
      const type: string = part.type
      if (type === 'year' || type === 'relatedYear') year = Number(part.value)
      else if (part.type === 'month') month = part.value
      else if (part.type === 'day') day = Number(part.value)
    }
    parts = { year, month, day }
    this.#parts.set(key, parts)
    return parts
  }

  year(date: Date): number {
    return this.#read(date).year
  }

  day(date: Date): number {
    return this.#read(date).day
  }

  startOfMonth(date: Date): Date {
    return addDays(startOfDay(date), 1 - this.#read(date).day)
  }

  /** The first day of the month after the one starting on `start`. */
  #next(start: Date): Date {
    const key = isoDate(start)
    let next = this.#nextMonth.get(key)
    if (next) return next
    next = addDays(start, 1)
    for (let step = 1; step < 40 && this.#read(next).day !== 1; step += 1) next = addDays(next, 1)
    this.#nextMonth.set(key, next)
    return next
  }

  /** The first day of the month before the one starting on `start`. */
  #previous(start: Date): Date {
    return this.startOfMonth(addDays(start, -1))
  }

  /** The first day of the year `date` is in. */
  #startOfYear(date: Date): Date {
    let start = this.startOfMonth(date)
    const year = this.#read(start).year
    for (let step = 0; step < 14; step += 1) {
      const previous = this.#previous(start)
      if (this.#read(previous).year !== year) break
      start = previous
    }
    return start
  }

  /** The first day of the year after the one starting on `start`. */
  #nextYear(start: Date): Date {
    const year = this.#read(start).year
    let next = this.#next(start)
    for (let step = 0; step < 14 && this.#read(next).year === year; step += 1)
      next = this.#next(next)
    return next
  }

  month(date: Date): number {
    const start = this.startOfMonth(date)
    const key = isoDate(start)
    let index = this.#monthIndex.get(key)
    if (index !== undefined) return index
    index = differenceInMonthsWithin(this, this.#startOfYear(start), start)
    this.#monthIndex.set(key, index)
    return index
  }

  endOfMonth(date: Date): Date {
    return addDays(this.#next(this.startOfMonth(date)), -1)
  }

  daysInMonth(date: Date): number {
    const start = this.startOfMonth(date)
    return differenceInDays(this.#next(start), start)
  }

  monthsInYear(year: number): number {
    const start = this.#yearStart(year)
    return differenceInMonthsWithin(this, start, addDays(this.#nextYear(start), -1)) + 1
  }

  /** The year's average length in days, measured once around 2000. */
  get #averageYear(): number {
    if (this.#yearLength === undefined) {
      const start = this.#startOfYear(makeDate(2000, 0, 1))
      let next = start
      for (let year = 0; year < 4; year += 1) next = this.#nextYear(next)
      this.#yearLength = differenceInDays(next, start) / 4
    }
    return this.#yearLength
  }

  /** The first day of `year`: a jump by its average length, then a step or two to correct it. */
  #yearStart(year: number): Date {
    const anchor = makeDate(2000, 6, 1)
    const estimate = addDays(
      anchor,
      Math.round((year - this.#read(anchor).year) * this.#averageYear),
    )
    let start = this.#startOfYear(estimate)
    for (let step = 0; step < 50; step += 1) {
      const found = this.#read(start).year
      if (found === year) break
      start = found < year ? this.#nextYear(start) : this.#startOfYear(addDays(start, -1))
    }
    return start
  }

  monthStart(year: number, month: number): Date {
    let start = this.#yearStart(year)
    for (let index = 0; index < month; index += 1) {
      const next = this.#next(start)
      if (this.#read(next).year !== year) break
      start = next
    }
    return start
  }

  addMonths(date: Date, amount: number): Date {
    let start = this.startOfMonth(date)
    const steps = Math.min(Math.abs(Math.trunc(amount)), 2400)
    for (let step = 0; step < steps; step += 1) {
      start = amount > 0 ? this.#next(start) : this.#previous(start)
    }
    return withDay(this, start, this.#read(date).day)
  }

  addYears(date: Date, amount: number): Date {
    const year = this.year(date) + Math.trunc(amount)
    const month = Math.min(this.month(date), this.monthsInYear(year) - 1)
    return withDay(this, this.monthStart(year, month), this.#read(date).day)
  }
}

/** The day `day` of the month starting on `start`, or its last day. */
function withDay(system: CalendarSystem, start: Date, day: number): Date {
  return addDays(start, Math.min(day, system.daysInMonth(start)) - 1)
}

/** How many months from the month starting `from` to the one `to` is in (same year or close). */
function differenceInMonthsWithin(system: CalendarSystem, from: Date, to: Date): number {
  let count = 0
  let start = system.startOfMonth(from)
  const end = system.startOfMonth(to)
  while (compareDays(start, end) < 0 && count < 2400) {
    start = system.addMonths(start, 1)
    count += 1
  }
  return count
}

const systems = new Map<string, CalendarSystem>([['gregory', gregorian]])

/**
 * The calendar system `Intl` calls `id`: `gregory` (and those with Gregorian months, such as
 * `buddhist` and `japanese`) natively, anything else Intl knows through Intl. An `id` Intl
 * doesn't know is Gregorian.
 */
export function calendarSystem(id: string | undefined): CalendarSystem {
  const name = id ?? 'gregory'
  let system = systems.get(name)
  if (system) return system
  let known: boolean
  try {
    known = new Intl.DateTimeFormat(`en-u-ca-${name}`).resolvedOptions().calendar === name
  } catch {
    known = false
  }
  system = !known || GREGORIAN_MONTHS.has(name) ? gregorian : new IntlCalendarSystem(name)
  systems.set(name, system)
  return system
}

// ---------------------------------------------------------------------------------------------
// Weeks

/** Where a locale's weeks start, and how many days of a new year its first week needs. */
export interface WeekInfo {
  firstDay: DayOfWeekNumber
  minimalDays: number
}

interface IntlWeekInfo {
  firstDay: number
  minimalDays?: number
}

// CLDR's week data, for a browser whose Intl.Locale has no getWeekInfo() (Firefox): the regions
// whose weeks start on a Sunday, Saturday or Friday (the rest start on a Monday), and those whose
// first week needs four days of the year (the rest need one).
const SUNDAY =
  'AG AS BD BR BS BT BW BZ CA CN CO DM DO ET GT GU HK HN ID IL IN JM JP KE KH KR LA MH MM MO MT MX MZ NI NP PA PE PH PK PR PT PY SA SG SV TH TT TW UM US VE VI WS YE ZA ZW'
const SATURDAY = 'AE AF BH DJ DZ EG IQ IR JO KW LY OM QA SD SY'
const FRIDAY = 'MV'
const FOUR_DAYS =
  'AD AN AT AX BE BG CH CZ DE DK EE ES FI FJ FO FR GB GF GG GI GP GR HU IE IM IS IT JE LI LT LU MC MQ NL NO PL RE RU SE SJ SK SM VA'

/**
 * The week a locale uses: its first day from `Intl.Locale#getWeekInfo()`, and the days a first
 * week needs from CLDR's data (Intl no longer gives them), as is the first day without Intl's.
 */
export function weekInfo(locale: string): WeekInfo {
  try {
    const intl = new Intl.Locale(locale) as Intl.Locale & {
      getWeekInfo?: () => IntlWeekInfo
      weekInfo?: IntlWeekInfo
    }
    const region = intl.maximize().region ?? ''
    const has = (list: string) => list.split(' ').includes(region)
    const info = intl.getWeekInfo?.() ?? intl.weekInfo
    const firstDay = info
      ? ((info.firstDay % 7) as DayOfWeekNumber)
      : has(SUNDAY)
        ? 0
        : has(SATURDAY)
          ? 6
          : has(FRIDAY)
            ? 5
            : 1
    // Intl dropped `minimalDays` from the week info (browsers that had it still give it).
    return { firstDay, minimalDays: info?.minimalDays ?? (has(FOUR_DAYS) ? 4 : 1) }
  } catch {
    return { firstDay: 0, minimalDays: 1 }
  }
}

/**
 * The week number of `date`, as date-fns' `getWeek` counts it (react-day-picker's): week 1 is the
 * week holding day `firstWeekContainsDate` of the year, in `system`'s years.
 */
export function weekNumber(
  date: Date,
  system: CalendarSystem,
  weekStartsOn: DayOfWeekNumber,
  firstWeekContainsDate: number,
): number {
  const firstWeek = (year: number) =>
    startOfWeek(addDays(system.monthStart(year, 0), firstWeekContainsDate - 1), weekStartsOn)
  const year = system.year(date)
  const next = firstWeek(year + 1)
  let start: Date
  if (compareDays(date, next) >= 0) start = next
  else {
    const current = firstWeek(year)
    start = compareDays(date, current) >= 0 ? current : firstWeek(year - 1)
  }
  return Math.round(differenceInDays(startOfWeek(date, weekStartsOn), start) / 7) + 1
}

// ---------------------------------------------------------------------------------------------
// Matchers and ranges, as react-day-picker's

/** A range of days. While it's being picked, `to` is unset. */
export interface DateRange {
  from: Date | undefined
  to?: Date | undefined
}

/** The days before `before`. */
export interface DateBefore {
  before: Date
}

/** The days after `after`. */
export interface DateAfter {
  after: Date
}

/** The days between `after` and `before` (both left out), or outside them when `after` is later. */
export interface DateInterval {
  before: Date
  after: Date
}

/** The days falling on these days of the week (0 for Sunday). */
export interface DayOfWeek {
  dayOfWeek: number | number[]
}

/**
 * Which days something applies to, as react-day-picker's matchers: `true` (every day), a date,
 * several dates, a range (`{ from, to }`), `{ before }`, `{ after }`, both, `{ dayOfWeek }`, or a
 * function of the date. `@disabled`, `@hidden` and `@modifiers` take one, or an array of them.
 */
export type Matcher =
  | boolean
  | Date
  | Date[]
  | DateRange
  | DateBefore
  | DateAfter
  | DateInterval
  | DayOfWeek
  | ((date: Date) => boolean)

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

/** Whether `range` holds `date`; with `excludeEnds`, its first and last days don't count. */
export function rangeIncludesDate(range: DateRange, date: Date, excludeEnds = false): boolean {
  let { from, to } = range
  if (from && to) {
    if (differenceInDays(to, from) < 0) [from, to] = [to, from]
    const edge = excludeEnds ? 1 : 0
    return differenceInDays(date, from) >= edge && differenceInDays(to, date) >= edge
  }
  if (!excludeEnds && to) return isSameDay(to, date)
  if (!excludeEnds && from) return isSameDay(from, date)
  return false
}

/** Whether `date` matches any of `matchers` (see `Matcher`). */
export function isMatch(date: Date, matchers: Matcher | Matcher[] | undefined): boolean {
  if (matchers === undefined) return false
  const list: Matcher[] = Array.isArray(matchers) ? matchers : [matchers]
  return list.some(matcher => {
    if (typeof matcher === 'boolean') return matcher
    if (typeof matcher === 'function') return matcher(date)
    if (matcher instanceof Date) return isSameDay(date, matcher)
    if (Array.isArray(matcher)) return matcher.some(day => isSameDay(date, day))
    if (!isObject(matcher)) return false
    if ('from' in matcher) return rangeIncludesDate(matcher as DateRange, date)
    if ('dayOfWeek' in matcher) {
      const days = (matcher as DayOfWeek).dayOfWeek
      return Array.isArray(days) ? days.includes(date.getDay()) : days === date.getDay()
    }
    if ('before' in matcher && 'after' in matcher) {
      const { before, after } = matcher as DateInterval
      const isBefore = differenceInDays(before, date) > 0
      const isAfter = differenceInDays(after, date) < 0
      return differenceInDays(before, after) > 0 ? isAfter && isBefore : isBefore || isAfter
    }
    if ('after' in matcher) return differenceInDays(date, (matcher as DateAfter).after) > 0
    if ('before' in matcher) return differenceInDays((matcher as DateBefore).before, date) > 0
    return false
  })
}

/** Whether any day of a range matches `matchers`. */
export function rangeContainsMatch(
  range: { from: Date; to: Date },
  matchers: Matcher | Matcher[],
): boolean {
  let from = range.from
  let to = range.to
  if (compareDays(to, from) < 0) [from, to] = [to, from]
  for (let day = startOfDay(from); compareDays(day, to) <= 0; day = addDays(day, 1)) {
    if (isMatch(day, matchers)) return true
  }
  return false
}

/**
 * The range a click on `date` makes of `range`, as react-day-picker's `addToRange`: the first
 * click starts a range, the next ends it (or starts it earlier), and a click on an end moves it.
 * `min` and `max` bound the range's length in days, and `required` keeps a range from emptying.
 */
export function addToRange(
  date: Date,
  range: DateRange | undefined,
  min = 0,
  max = 0,
  required = false,
): DateRange | undefined {
  const { from, to } = range ?? { from: undefined, to: undefined }
  let next: DateRange | undefined
  if (!from && !to) {
    next = { from: date, to: min > 0 ? undefined : date }
  } else if (from && !to) {
    if (isSameDay(from, date)) next = required ? { from, to: undefined } : undefined
    else if (compareDays(date, from) < 0) next = { from: date, to: from }
    else next = { from, to: date }
  } else if (from && to) {
    if (isSameDay(from, date) && isSameDay(to, date)) next = required ? { from, to } : undefined
    else if (isSameDay(from, date)) next = { from, to: min > 0 ? undefined : date }
    else if (isSameDay(to, date)) next = { from: date, to: min > 0 ? undefined : date }
    else if (compareDays(date, from) < 0) next = { from: date, to }
    else next = { from, to: date }
  } else if (to) {
    next = compareDays(date, to) < 0 ? { from: date, to } : { from: to, to: date }
  }
  if (next?.from && next.to) {
    const days = differenceInDays(next.to, next.from)
    if ((max > 0 && days > max) || (min > 1 && days < min)) next = { from: date, to: undefined }
  }
  return next
}

// ---------------------------------------------------------------------------------------------
// Locales

/** A locale, calendar and numbering system, and the Intl formatting they give. */
export interface CalendarLocale {
  /** The BCP 47 tag Intl formats with, its calendar and numbering system included. */
  readonly tag: string
  /** Its language, `en` for `en-US`. */
  readonly language: string
  /** The calendar, as Intl names it: `gregory`, `persian`… */
  readonly calendar: string
  /** The numbering system, as Intl names it: `latn`, `arab`, `arabext`… */
  readonly numerals: string
  /** Formats a date with Intl, in this locale, calendar and numbering system. */
  format(date: Date, options: Intl.DateTimeFormatOptions): string
  /** Formats a number with Intl, in this locale's numbering system. */
  formatNumber(value: number, options?: Intl.NumberFormatOptions): string
}

const formats = new Map<string, Intl.DateTimeFormat>()
const numberFormats = new Map<string, Intl.NumberFormat>()
const locales = new Map<string, CalendarLocale>()

/**
 * A `CalendarLocale` for `locale` (default `en-US`, as react-day-picker's). The calendar is
 * `calendar`, else the one the tag names (`-u-ca-persian`), else Gregorian; the numbering system
 * is `numerals`, else the tag's (`-u-nu-arab`), else Latin digits. Those defaults are
 * react-day-picker's: Arabic month names in a Gregorian calendar for `ar-SA`, unless asked.
 */
export function calendarLocale(
  locale: string | undefined,
  calendar?: string,
  numerals?: string,
): CalendarLocale {
  const key = `${locale ?? ''}|${calendar ?? ''}|${numerals ?? ''}`
  const cached = locales.get(key)
  if (cached) return cached
  let base: Intl.Locale
  try {
    base = new Intl.Locale(locale ?? 'en-US')
  } catch {
    base = new Intl.Locale('en-US')
  }
  let tag: string
  try {
    tag = new Intl.Locale(base.toString(), {
      calendar: calendar ?? base.calendar ?? 'gregory',
      numberingSystem: numerals ?? base.numberingSystem ?? 'latn',
    }).toString()
  } catch {
    tag = base.toString()
  }
  const resolved = new Intl.DateTimeFormat(tag).resolvedOptions()
  const value: CalendarLocale = {
    tag,
    language: base.language,
    calendar: resolved.calendar,
    numerals: resolved.numberingSystem,
    format(date, options) {
      const formatKey = `${tag}|${JSON.stringify(options)}`
      let format = formats.get(formatKey)
      if (!format) formats.set(formatKey, (format = new Intl.DateTimeFormat(tag, options)))
      return format.format(date)
    },
    formatNumber(number, options = {}) {
      const formatKey = `${tag}|${JSON.stringify(options)}`
      let format = numberFormats.get(formatKey)
      if (!format) {
        numberFormats.set(
          formatKey,
          (format = new Intl.NumberFormat(tag, { useGrouping: false, ...options })),
        )
      }
      return format.format(number)
    },
  }
  locales.set(key, value)
  return value
}
