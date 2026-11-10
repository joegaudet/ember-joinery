/**
 * A range of days, as Joinery's dates are: `from` and `to` are `Date`s (at local midnight), and
 * either may be missing while the range is being chosen. The same shape as shadcn's Calendar
 * (react-day-picker's `DateRange`).
 */
export interface DateRange {
  from: Date | undefined
  to?: Date | undefined
}

const ISO_DATE = /^(\d{4})-(\d{2})-(\d{2})/

/**
 * The calendar day a value stands for, as a local `Date` at midnight: from a `Date`, or from a
 * string starting with `YYYY-MM-DD` (the time, if any, is ignored). Anything else is
 * `undefined`.
 */
export function toDate(value: unknown): Date | undefined {
  if (value instanceof Date) {
    return isNaN(+value)
      ? undefined
      : new Date(value.getFullYear(), value.getMonth(), value.getDate())
  }
  if (typeof value === 'string') {
    const match = ISO_DATE.exec(value)
    if (match) return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]))
  }
  return undefined
}

/** A local `Date` as `YYYY-MM-DD`, the form the harnesses and `data-test-jn-value` use. */
export function toIsoDate(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

/** Whether two dates fall on the same calendar day, in local time. */
export function isSameDay(a: Date | undefined, b: Date | undefined): boolean {
  return Boolean(
    a &&
    b &&
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate(),
  )
}

/** How a date is written: a locale, and `Intl.DateTimeFormat` options. */
export interface FormatOptions {
  /** A BCP 47 locale (`en-US`, `ar`). Default: the browser's. */
  locale?: string
  /** `Intl.DateTimeFormat` options. Default `{ dateStyle: 'long' }` ("March 4, 2026"). */
  format?: Intl.DateTimeFormatOptions
}

const DEFAULT_FORMAT: Intl.DateTimeFormatOptions = { dateStyle: 'long' }

function formatter({ locale, format }: FormatOptions): Intl.DateTimeFormat {
  return new Intl.DateTimeFormat(locale, format ?? DEFAULT_FORMAT)
}

/** A date as text, e.g. "March 4, 2026"; `''` for no date. */
export function formatDate(value: Date | undefined | null, options: FormatOptions = {}): string {
  const date = toDate(value)
  return date ? formatter(options).format(date) : ''
}

/**
 * A range as text, with `Intl`'s range format ("March 4 – 9, 2026"); the start with a dash
 * while the end is missing ("March 4, 2026 –"), and `''` for no range.
 */
export function formatDateRange(
  value: DateRange | undefined | null,
  options: FormatOptions = {},
): string {
  const from = toDate(value?.from)
  const to = toDate(value?.to)
  const f = formatter(options)
  if (from && to) return f.formatRange(from, to)
  if (from) return `${f.format(from)} –`
  if (to) return `– ${f.format(to)}`
  return ''
}

/**
 * The day typed text names, or `undefined` when it names none: `YYYY-MM-DD`, or whatever the
 * browser's `Date` reads ("June 01, 2025", "6/1/2025" in English), as upstream's
 * date-picker-input reads it, as long as it has a four-digit year (so a half-typed "6" isn't
 * read as 2001). The time of day, if any, is dropped.
 */
export function parseDate(text: string): Date | undefined {
  const trimmed = text.trim()
  if (!/\d{4}/.test(trimmed)) return undefined
  const iso = ISO_DATE.exec(trimmed)
  if (iso && trimmed.length === 10) return toDate(trimmed)
  const parsed = new Date(trimmed)
  return toDate(parsed)
}
