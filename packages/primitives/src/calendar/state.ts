import { cached, tracked } from '@glimmer/tracking'
import { modifier } from 'ember-modifier'
import { ControllableState } from '../controllable-state.ts'
import { getDirection, type Direction } from '../direction.gts'
import {
  addDays,
  addToRange,
  calendarLocale,
  calendarSystem,
  compareDays,
  endOfWeek,
  isMatch,
  isSameDay,
  isoDate,
  isoMonth,
  rangeContainsMatch,
  rangeIncludesDate,
  startOfDay,
  startOfWeek,
  weekInfo,
  weekNumber,
  type CalendarLocale,
  type CalendarSystem,
  type DateRange,
  type DayOfWeekNumber,
  type Matcher,
} from './dates.ts'

/** How a calendar selects: one day, any number of days, or a range. */
export type CalendarMode = 'single' | 'multiple' | 'range'

/**
 * What a month's caption shows: its name (`label`), or a month and a year dropdown, or only one
 * of them, as react-day-picker's `captionLayout`.
 */
export type CaptionLayout = 'label' | 'dropdown' | 'dropdown-months' | 'dropdown-years'

/** A calendar's selection: a date (`single`), dates (`multiple`) or a range (`range`). */
export type CalendarValue = Date | Date[] | DateRange | undefined

/**
 * What applies to a day, as react-day-picker's modifiers: its own flags, its selection, and one
 * entry for each of the calendar's `@modifiers`.
 */
export interface CalendarModifiers {
  today: boolean
  outside: boolean
  disabled: boolean
  hidden: boolean
  focused: boolean
  selected: boolean
  range_start: boolean
  range_middle: boolean
  range_end: boolean
  [modifier: string]: boolean
}

/** What `@onValueChange` hears with the new selection: the day pressed and its modifiers. */
export interface CalendarSelectDetails {
  date: Date
  modifiers: CalendarModifiers
  event: Event
}

/**
 * The text a calendar formats, each from Intl in the calendar's locale (`CalendarLocale`), as
 * react-day-picker's formatters. Pass any of them in `@formatters` to change it.
 */
export interface CalendarFormatters {
  /** A month's caption: `January 2026`. */
  formatCaption(month: Date, locale: CalendarLocale): string
  /** A day's number: `12`. */
  formatDay(date: Date, locale: CalendarLocale): string
  /** An option in the month dropdown: `January`. */
  formatMonthDropdown(month: Date, locale: CalendarLocale): string
  /** An option in the year dropdown: `2026`. */
  formatYearDropdown(year: Date, locale: CalendarLocale): string
  /** A column's heading: `Su`. */
  formatWeekdayName(weekday: Date, locale: CalendarLocale): string
  /** A week's number: `03`. */
  formatWeekNumber(weekNumber: number, locale: CalendarLocale): string
  /** The heading over the week numbers: none. */
  formatWeekNumberHeader(locale: CalendarLocale): string
}

/**
 * The names a calendar gives its parts, for assistive technology, as react-day-picker's labels,
 * in English by default. Pass any of them in `@labels` for words of your own.
 */
export interface CalendarLabels {
  /** A day's button: `Today, Monday, January 12, 2026, selected`. */
  labelDayButton(date: Date, modifiers: CalendarModifiers, locale: CalendarLocale): string
  /** A day's cell, when the days aren't buttons (no `@mode`). */
  labelGridcell(date: Date, modifiers: CalendarModifiers, locale: CalendarLocale): string
  /** A month's grid: `January 2026`. */
  labelGrid(month: Date, locale: CalendarLocale): string
  /** The month dropdown: `Choose the Month`. */
  labelMonthDropdown(locale: CalendarLocale): string
  /** The year dropdown: `Choose the Year`. */
  labelYearDropdown(locale: CalendarLocale): string
  /** The navigation: none, as upstream's. */
  labelNav(locale: CalendarLocale): string
  /** The next-month button: `Go to the Next Month`. */
  labelNext(month: Date | undefined, locale: CalendarLocale): string
  /** The previous-month button: `Go to the Previous Month`. */
  labelPrevious(month: Date | undefined, locale: CalendarLocale): string
  /** A column: `Sunday`. */
  labelWeekday(weekday: Date, locale: CalendarLocale): string
  /** A week's number: `Week 3`. */
  labelWeekNumber(weekNumber: number, locale: CalendarLocale): string
  /** The week numbers' column: `Week Number`. */
  labelWeekNumberHeader(locale: CalendarLocale): string
}

const narrow = new WeakMap<CalendarLocale, boolean>()

/** Whether a locale's abbreviated weekday names are too long for a calendar's columns. */
function narrowWeekdays(locale: CalendarLocale): boolean {
  let value = narrow.get(locale)
  if (value === undefined) {
    // 4 to 10 January 2026 run Sunday to Saturday.
    value = Array.from({ length: 7 }, (_, index) => new Date(2026, 0, 4 + index)).some(
      day => [...locale.format(day, { weekday: 'short' })].length > 4,
    )
    narrow.set(locale, value)
  }
  return value
}

/** Intl's formatting, as react-day-picker formats with date-fns. */
export const defaultCalendarFormatters: CalendarFormatters = {
  formatCaption: (month, locale) => locale.format(month, { month: 'long', year: 'numeric' }),
  formatDay: (date, locale) => locale.format(date, { day: 'numeric' }),
  formatMonthDropdown: (month, locale) => locale.format(month, { month: 'long' }),
  formatYearDropdown: (year, locale) => locale.format(year, { year: 'numeric' }),
  formatWeekdayName(weekday, locale) {
    // react-day-picker shows date-fns' short day names (CLDR's "short" width: Su, Mo, Tu),
    // which Intl doesn't offer. In English they are the abbreviation's first two letters; in
    // a language whose abbreviations are whole words (Persian, Arabic), the narrow names fit
    // the columns.
    const name = locale.format(weekday, { weekday: 'short' })
    if (locale.language === 'en') return name.slice(0, 2)
    return narrowWeekdays(locale) ? locale.format(weekday, { weekday: 'narrow' }) : name
  },
  formatWeekNumber: (weekNumber, locale) =>
    locale.formatNumber(weekNumber, { minimumIntegerDigits: 2 }),
  formatWeekNumberHeader: () => '',
}

/** react-day-picker's English labels, with Intl's full date for each day. */
export const defaultCalendarLabels: CalendarLabels = {
  labelDayButton(date, modifiers, locale) {
    let label = locale.format(date, { dateStyle: 'full' })
    if (modifiers.today) label = `Today, ${label}`
    if (modifiers.selected) label = `${label}, selected`
    return label
  },
  labelGridcell(date, modifiers, locale) {
    const label = locale.format(date, { dateStyle: 'full' })
    return modifiers.today ? `Today, ${label}` : label
  },
  labelGrid: (month, locale) => locale.format(month, { month: 'long', year: 'numeric' }),
  labelMonthDropdown: () => 'Choose the Month',
  labelYearDropdown: () => 'Choose the Year',
  labelNav: () => '',
  labelNext: () => 'Go to the Next Month',
  labelPrevious: () => 'Go to the Previous Month',
  labelWeekday: (weekday, locale) => locale.format(weekday, { weekday: 'long' }),
  labelWeekNumber: weekNumber => `Week ${weekNumber}`,
  labelWeekNumberHeader: () => 'Week Number',
}

/** The parts and states react-day-picker gives a class each (`classNames`). */
export interface CalendarClassNames {
  root: string
  months: string
  month: string
  nav: string
  button_previous: string
  button_next: string
  chevron: string
  month_caption: string
  caption_label: string
  dropdowns: string
  dropdown_root: string
  dropdown: string
  months_dropdown: string
  years_dropdown: string
  month_grid: string
  weekdays: string
  weekday: string
  weeks: string
  week: string
  week_number_header: string
  week_number: string
  day: string
  day_button: string
  footer: string
  today: string
  outside: string
  disabled: string
  hidden: string
  focused: string
  selected: string
  range_start: string
  range_middle: string
  range_end: string
}

/** react-day-picker's default classes, `rdp-<part>`: what the styled Calendar renders too. */
export const defaultCalendarClassNames: CalendarClassNames = Object.fromEntries(
  [
    'root',
    'months',
    'month',
    'nav',
    'button_previous',
    'button_next',
    'chevron',
    'month_caption',
    'caption_label',
    'dropdowns',
    'dropdown_root',
    'dropdown',
    'months_dropdown',
    'years_dropdown',
    'month_grid',
    'weekdays',
    'weekday',
    'weeks',
    'week',
    'week_number_header',
    'week_number',
    'day',
    'day_button',
    'footer',
    'today',
    'outside',
    'disabled',
    'hidden',
    'focused',
    'selected',
    'range_start',
    'range_middle',
    'range_end',
  ].map(part => [part, `rdp-${part}`]),
) as unknown as CalendarClassNames

/** What a calendar takes: the styled `<Calendar>` and the headless one alike. */
export interface CalendarArgs {
  /** How it selects: `single`, `multiple` or `range`. Without one, the days aren't buttons. */
  mode?: CalendarMode
  /**
   * The selection, controlled: a `Date` (`single`), `Date[]` (`multiple`) or `{ from, to }`
   * (`range`). With `@onValueChange` and no `@defaultValue`, it is controlled even while
   * `undefined`, so nothing is selected until you pass a value.
   */
  value?: Date | Date[] | DateRange
  /** The first selection, uncontrolled. */
  defaultValue?: Date | Date[] | DateRange
  /** Called with each new selection (`undefined` when emptied), and the day pressed. */
  onValueChange?(value: CalendarValue, details: CalendarSelectDetails): void
  /** Whether the selection can't be emptied: pressing the selected day keeps it. */
  required?: boolean
  /** `multiple`: the fewest days it keeps. `range`: the fewest nights a range spans. */
  min?: number
  /** `multiple`: the most days (a press past it starts again). `range`: the most nights. */
  max?: number
  /** `range`: start again when a range would hold a disabled day. */
  excludeDisabled?: boolean
  /** The first month shown, controlled. Any day of it. */
  month?: Date
  /** The first month shown at first. Default: today's. */
  defaultMonth?: Date
  /** Called with the first day of each new first month. */
  onMonthChange?: (month: Date) => void
  /** The earliest month you can go to. With a year dropdown, default 100 years back. */
  startMonth?: Date
  /** The latest month you can go to. With a year dropdown, default the end of this year. */
  endMonth?: Date
  /** How many months it shows side by side. Default 1. */
  numberOfMonths?: number
  /** Whether the buttons move by `@numberOfMonths` rather than one month. */
  pagedNavigation?: boolean
  /** What each month's caption shows. Default `label`. */
  captionLayout?: CaptionLayout
  /** Whether it shows the days of the months around each one (as `outside` days). */
  showOutsideDays?: boolean
  /** Whether every month shows six weeks. */
  fixedWeeks?: boolean
  /** Whether a column of week numbers goes before the days. */
  showWeekNumber?: boolean
  /** Whether the row of weekday names is left out. */
  hideWeekdays?: boolean
  /** Whether the previous and next buttons are left out. */
  hideNavigation?: boolean
  /** Whether you can't move to another month. */
  disableNavigation?: boolean
  /** The days you can't select (see `Matcher`). */
  disabled?: Matcher | Matcher[]
  /** The days that aren't shown. */
  hidden?: Matcher | Matcher[]
  /** Modifiers of your own, by name: each day it matches has it, and its class. */
  modifiers?: Record<string, Matcher | Matcher[] | undefined>
  /** Classes for modifiers, by name; one for a built-in modifier replaces its class. */
  modifiersClassNames?: Record<string, string>
  /** The day counted as today. Default: today. */
  today?: Date
  /** The locale for names and dates, a BCP 47 tag. Default `en-US`, as react-day-picker's. */
  locale?: string
  /** The calendar, as Intl names it (`persian`, `islamic-umalqura`). Default Gregorian. */
  calendar?: string
  /** The numbering system, as Intl names it (`arab`, `arabext`). Default Latin digits. */
  numerals?: string
  /** The first day of the week, 0 for Sunday. Default: the locale's. */
  weekStartsOn?: DayOfWeekNumber
  /** Which day of January the first week holds, for week numbers. Default: the locale's. */
  firstWeekContainsDate?: number
  /** The text direction, when the document's shouldn't decide. */
  dir?: Direction
  /** Whether it takes focus when it renders, on the day focus goes to. */
  autoFocus?: boolean
  /** Names of your own for its parts (see `CalendarLabels`). */
  labels?: Partial<CalendarLabels>
  /** Formatting of your own (see `CalendarFormatters`). */
  formatters?: Partial<CalendarFormatters>
  /** Called with each day pressed, selected or not. */
  onDayClick?: (date: Date, modifiers: CalendarModifiers, event: MouseEvent) => void
}

/** A day the calendar shows: the date, the month it's shown in, and what applies to it. */
export interface CalendarDay {
  /** `yyyy-MM-dd`, and the month shown: unique in the calendar. */
  key: string
  /** `yyyy-MM-dd`. */
  iso: string
  /** The day, at local midnight. */
  date: Date
  /** The first day of the month it's shown in. */
  displayMonth: Date
  /** Whether it belongs to a month around the one it's shown in. */
  outside: boolean
  modifiers: CalendarModifiers
  /** Its number, formatted: `12`. */
  label: string
  /** Its button's name. */
  buttonLabel: string
  /** Its cell's name, when it has no button. */
  cellLabel: string | undefined
  /** Whether it is a button: it is shown and the calendar selects. */
  isButton: boolean
  /** Whether it shows its number: it isn't hidden. */
  isShown: boolean
  /** 0 for the one day in the tab order, -1 for the rest. */
  tabIndex: number
  /** The day in the locale's short form, as upstream's day button's `data-day`. */
  localeDate: string
  /** `yyyy-MM` for an outside day, as upstream's `data-month`. */
  outsideMonth: string | undefined
  /** Its cell's classes: the day's, each modifier's, and your `@modifiersClassNames`. */
  className: string
  /** Selected on its own, not as part of a range: upstream's `data-selected-single`. */
  selectedSingle: boolean
}

/** A week row: its number, and its seven days. */
export interface CalendarWeek {
  key: string
  number: number
  numberText: string
  numberLabel: string
  days: CalendarDay[]
}

/** An option of a month or year dropdown. */
export interface CalendarDropdownOption {
  value: number
  label: string
  disabled: boolean
  selected: boolean
}

/** A month the calendar shows. */
export interface CalendarMonth {
  /** `yyyy-MM-dd` of its first day. */
  key: string
  /** Its place among the months shown, from 0. */
  index: number
  /** Its first day. */
  date: Date
  caption: string
  gridLabel: string
  weeks: CalendarWeek[]
  /** The month dropdown's options, when it has one. */
  monthOptions: CalendarDropdownOption[] | undefined
  /** The year dropdown's options, when it has one. */
  yearOptions: CalendarDropdownOption[] | undefined
  /** The month's name as the month dropdown shows it. */
  monthText: string
  /** The year as the year dropdown shows it. */
  yearText: string
}

/** A column's weekday. */
export interface CalendarWeekday {
  key: string
  name: string
  label: string
}

/** A day the focus is on: which date, shown in which month. */
interface DayRef {
  date: Date
  displayMonth: Date
}

type MoveBy = 'day' | 'week' | 'month' | 'year' | 'startOfWeek' | 'endOfWeek'
type MoveDirection = 'before' | 'after'

function sameRef(a: DayRef | undefined, b: DayRef): boolean {
  return Boolean(a && isSameDay(a.date, b.date) && isSameDay(a.displayMonth, b.displayMonth))
}

function isRange(value: unknown): value is DateRange {
  return typeof value === 'object' && value !== null && !Array.isArray(value) && 'from' in value
}

const KEYS: Record<string, (shift: boolean, rtl: boolean) => [MoveBy, MoveDirection]> = {
  ArrowLeft: (shift, rtl) => [shift ? 'month' : 'day', rtl ? 'after' : 'before'],
  ArrowRight: (shift, rtl) => [shift ? 'month' : 'day', rtl ? 'before' : 'after'],
  ArrowDown: shift => [shift ? 'year' : 'week', 'after'],
  ArrowUp: shift => [shift ? 'year' : 'week', 'before'],
  PageUp: shift => [shift ? 'year' : 'month', 'before'],
  PageDown: shift => [shift ? 'year' : 'month', 'after'],
  Home: () => ['startOfWeek', 'before'],
  End: () => ['endOfWeek', 'after'],
}

/**
 * A calendar's state and behaviour, as react-day-picker's `DayPicker` has them: the months it
 * shows and how to move between them, its selection, its days' modifiers and labels, and the one
 * day in the tab order with the arrow keys moving focus. The styled `<Calendar>` and the headless
 * one both render from it.
 *
 *   calendar = new CalendarState(() => this.args)
 *   {{#each this.calendar.months as |month|}} … {{/each}}
 */
export class CalendarState {
  readonly #args: () => CalendarArgs
  readonly #classNames: () => Partial<CalendarClassNames> | undefined
  /** The first month shown: `@month`, `@defaultMonth` and `@onMonthChange`. */
  readonly month: ControllableState<Date>
  /** The selection the calendar holds itself, uncontrolled. */
  @tracked private ownValue: { value: CalendarValue } | undefined
  /** The day with focus, while a day has it. */
  @tracked private focused: DayRef | undefined
  /** The last day that had focus, where focus goes back to. */
  @tracked private lastFocused: DayRef | undefined
  #root: HTMLElement | undefined

  /**
   * @param args the calendar's arguments, read live
   * @param classNames the headless component's `@classNames`; the styled one keeps the defaults
   */
  constructor(
    args: () => CalendarArgs,
    classNames: () => Partial<CalendarClassNames> | undefined = () => undefined,
  ) {
    this.#args = args
    this.#classNames = classNames
    this.month = new ControllableState<Date>({
      name: 'month',
      value: () => args().month,
      defaultValue: () => args().defaultMonth,
      onChange: () => args().onMonthChange,
      fallback: startOfDay(args().today ?? new Date()),
    })
    if (args().autoFocus) {
      // Nothing has had focus yet. The target is worked out without reading `focused`, which is
      // set next: the calendar is made while it renders, and Ember 6.12 asserts on a tracked
      // value written after it was read in the same render.
      const target = this.#focusTargetOf(this.grid, undefined, undefined)
      if (target) this.focused = { date: target.date, displayMonth: target.displayMonth }
    }
  }

  get args(): CalendarArgs {
    return this.#args()
  }

  /** The class of each part and state: react-day-picker's `rdp-*`, or the `@classNames` given. */
  get classNames(): CalendarClassNames {
    return { ...defaultCalendarClassNames, ...this.#classNames() }
  }

  /** The locale, calendar and numbering system everything is formatted in. */
  get locale(): CalendarLocale {
    const { locale, calendar, numerals } = this.#args()
    return calendarLocale(locale, calendar, numerals)
  }

  /** The calendar's months and years. */
  get system(): CalendarSystem {
    return calendarSystem(this.locale.calendar)
  }

  get weekStartsOn(): DayOfWeekNumber {
    return this.#args().weekStartsOn ?? weekInfo(this.locale.tag).firstDay
  }

  get firstWeekContainsDate(): number {
    return this.#args().firstWeekContainsDate ?? weekInfo(this.locale.tag).minimalDays
  }

  get formatters(): CalendarFormatters {
    return { ...defaultCalendarFormatters, ...this.#args().formatters }
  }

  get labels(): CalendarLabels {
    return { ...defaultCalendarLabels, ...this.#args().labels }
  }

  get today(): Date {
    return startOfDay(this.#args().today ?? new Date())
  }

  get numberOfMonths(): number {
    return Math.max(1, this.#args().numberOfMonths ?? 1)
  }

  get captionLayout(): CaptionLayout {
    return this.#args().captionLayout ?? 'label'
  }

  /** Whether the caption is dropdowns (a month dropdown, a year dropdown, or both). */
  get hasDropdowns(): boolean {
    return this.captionLayout.startsWith('dropdown')
  }

  /** Whether the days are buttons: the calendar selects, or listens for presses. */
  get isInteractive(): boolean {
    const { mode, onDayClick } = this.#args()
    return mode !== undefined || onDayClick !== undefined
  }

  /** `aria-multiselectable`: `true` for `multiple` and `range`. */
  get isMultiselectable(): boolean {
    const mode = this.#args().mode
    return mode === 'multiple' || mode === 'range'
  }

  /**
   * The first and last day you can go to: `@startMonth`'s first and `@endMonth`'s last, or with a
   * year dropdown, 100 years back to the end of this year, as react-day-picker's.
   */
  @cached
  get navBounds(): [start: Date | undefined, end: Date | undefined] {
    const { startMonth, endMonth } = this.#args()
    const system = this.system
    const hasYears = this.captionLayout === 'dropdown' || this.captionLayout === 'dropdown-years'
    const thisYear = system.year(this.today)
    let start: Date | undefined
    let end: Date | undefined
    if (startMonth) start = system.startOfMonth(startOfDay(startMonth))
    else if (hasYears) start = system.monthStart(thisYear - 100, 0)
    if (endMonth) end = system.endOfMonth(startOfDay(endMonth))
    else if (hasYears) {
      end = system.endOfMonth(system.monthStart(thisYear, system.monthsInYear(thisYear) - 1))
    }
    return [start, end]
  }

  /** `month`, kept where `@numberOfMonths` months from it fit between the bounds. */
  #clampFirstMonth(month: Date): Date {
    const system = this.system
    const [start, end] = this.navBounds
    let first = system.startOfMonth(startOfDay(month))
    const offset = this.numberOfMonths - 1
    if (end && compareDays(system.addMonths(first, offset), system.startOfMonth(end)) > 0) {
      first = system.addMonths(system.startOfMonth(end), -offset)
    }
    if (start && compareDays(first, start) < 0) first = start
    return system.startOfMonth(first)
  }

  /** The first day of the first month shown. */
  get firstMonth(): Date {
    return this.#clampFirstMonth(this.month.value)
  }

  /** The first day of each month shown. */
  @cached
  get displayMonths(): Date[] {
    const system = this.system
    const end = this.navBounds[1]
    const months: Date[] = []
    for (let index = 0; index < this.numberOfMonths; index += 1) {
      const month = system.addMonths(this.firstMonth, index)
      if (end && compareDays(month, end) > 0) break
      months.push(month)
    }
    return months
  }

  get #offset(): number {
    return this.#args().pagedNavigation ? this.numberOfMonths : 1
  }

  /** The month the previous button goes to, or `undefined` when there's none. */
  get previousMonth(): Date | undefined {
    if (this.#args().disableNavigation) return undefined
    const start = this.navBounds[0]
    const first = this.firstMonth
    if (start && compareDays(first, start) <= 0) return undefined
    return this.system.addMonths(first, -this.#offset)
  }

  /** The month the next button goes to, or `undefined` when there's none. */
  get nextMonth(): Date | undefined {
    if (this.#args().disableNavigation) return undefined
    const end = this.navBounds[1]
    const system = this.system
    const first = this.firstMonth
    if (
      end &&
      compareDays(system.addMonths(first, this.numberOfMonths), system.startOfMonth(end)) > 0
    ) {
      return undefined
    }
    return system.addMonths(first, this.#offset)
  }

  /** Shows `month` (any day of it) first, kept between the bounds, and tells `@onMonthChange`. */
  goToMonth = (month: Date): void => {
    if (this.#args().disableNavigation) return
    const system = this.system
    const [start, end] = this.navBounds
    let next = system.startOfMonth(startOfDay(month))
    if (start && compareDays(next, start) < 0) next = start
    if (end && compareDays(next, system.startOfMonth(end)) > 0) next = system.startOfMonth(end)
    this.month.set(next)
  }

  goToPrevious = (): void => {
    const month = this.previousMonth
    if (month) this.goToMonth(month)
  }

  goToNext = (): void => {
    const month = this.nextMonth
    if (month) this.goToMonth(month)
  }

  /** A month dropdown's change: shows that month of the year it was in. */
  changeMonth = (month: CalendarMonth, event: Event): void => {
    const index = Number((event.target as HTMLSelectElement).value)
    this.goToMonth(this.system.monthStart(this.system.year(month.date), index))
  }

  /** A year dropdown's change: shows the same month of that year. */
  changeYear = (month: CalendarMonth, event: Event): void => {
    const year = Number((event.target as HTMLSelectElement).value)
    const system = this.system
    const index = Math.min(system.month(month.date), system.monthsInYear(year) - 1)
    this.goToMonth(system.monthStart(year, index))
  }

  // ---------------------------------------------------------------------------------------------
  // Selection

  /**
   * Whether the caller owns the selection: they pass `@value`, or `@onValueChange` without a
   * `@defaultValue` (react-day-picker's rule: `onSelect` controls `selected`, even unset).
   */
  get isValueControlled(): boolean {
    const { value, defaultValue, onValueChange } = this.#args()
    return value !== undefined || (onValueChange !== undefined && defaultValue === undefined)
  }

  /** The selection now. */
  get selected(): CalendarValue {
    if (this.isValueControlled) return this.#args().value
    return this.ownValue ? this.ownValue.value : this.#args().defaultValue
  }

  /** Whether `date` is selected. */
  isSelected = (date: Date): boolean => {
    const selected = this.selected
    if (!selected) return false
    if (selected instanceof Date) return isSameDay(selected, date)
    if (Array.isArray(selected)) return selected.some(day => isSameDay(day, date))
    return rangeIncludesDate(selected, date)
  }

  #setValue(value: CalendarValue, details: CalendarSelectDetails): void {
    if (!this.isValueControlled) this.ownValue = { value }
    this.#args().onValueChange?.(value, details)
  }

  /** Selects `date` (or lets it go) by the calendar's mode, as a press on it does. */
  select(date: Date, modifiers: CalendarModifiers, event: Event): void {
    const { mode, required, min, max, excludeDisabled, disabled } = this.#args()
    const details = { date, modifiers, event }
    if (mode === 'single') {
      const selected = this.selected instanceof Date ? this.selected : undefined
      const next = !required && selected && isSameDay(selected, date) ? undefined : date
      this.#setValue(next, details)
    } else if (mode === 'multiple') {
      const selected = Array.isArray(this.selected) ? this.selected : undefined
      let next: Date[] | undefined
      if (this.isSelected(date)) {
        if (selected?.length === min) return
        if (required && selected?.length === 1) return
        next = selected?.filter(day => !isSameDay(day, date))
      } else {
        next = selected?.length === max ? [date] : [...(selected ?? []), date]
      }
      this.#setValue(next, details)
    } else if (mode === 'range') {
      const selected = isRange(this.selected) ? this.selected : undefined
      const next = addToRange(date, selected, min, max, required)
      if (excludeDisabled && disabled && next?.from && next.to) {
        if (rangeContainsMatch({ from: next.from, to: next.to }, disabled)) {
          next.from = date
          next.to = undefined
        }
      }
      this.#setValue(next, details)
    }
  }

  // ---------------------------------------------------------------------------------------------
  // Days

  /** The day's flags and your modifiers, before selection and focus. */
  #baseModifiers(date: Date, displayMonth: Date): CalendarModifiers {
    const args = this.#args()
    const [start, end] = this.navBounds
    const outside = !isSameDay(this.system.startOfMonth(date), displayMonth)
    const hidden =
      isMatch(date, args.hidden) ||
      Boolean(start && compareDays(date, start) < 0) ||
      Boolean(end && compareDays(date, end) > 0) ||
      (!args.showOutsideDays && outside)
    const modifiers: CalendarModifiers = {
      focused: false,
      disabled: isMatch(date, args.disabled),
      hidden,
      outside,
      today: isSameDay(date, this.today),
      selected: false,
      range_start: false,
      range_end: false,
      range_middle: false,
    }
    for (const [name, matcher] of Object.entries(args.modifiers ?? {})) {
      modifiers[name] = isMatch(date, matcher)
    }
    return modifiers
  }

  /** The days of one month's grid: whole weeks, or six of them with `@fixedWeeks`. */
  #daysOf(month: Date): Date[] {
    const weekStartsOn = this.weekStartsOn
    const days: Date[] = []
    const last = endOfWeek(this.system.endOfMonth(month), weekStartsOn)
    for (let day = startOfWeek(month, weekStartsOn); compareDays(day, last) <= 0;) {
      days.push(day)
      day = addDays(day, 1)
    }
    if (this.#args().fixedWeeks) {
      while (days.length < 42) days.push(addDays(days[days.length - 1]!, 1))
    }
    return days
  }

  /**
   * The day focus goes to with Tab, as react-day-picker picks it: the focused day, else the one
   * focused last, else the first selected, else today, else the first that can take focus.
   */
  get focusTarget(): DayRef | undefined {
    return this.#focusTargetOf(this.grid, this.focused, this.lastFocused)
  }

  #focusTargetOf(
    grid: { date: Date; displayMonth: Date; modifiers: CalendarModifiers }[][],
    focused: DayRef | undefined,
    lastFocused: DayRef | undefined,
  ) {
    const focusable = (modifiers: CalendarModifiers) =>
      !modifiers.disabled && !modifiers.hidden && !modifiers.outside
    let found: DayRef | undefined
    let priority = -1
    for (const days of grid) {
      for (const day of days) {
        if (!focusable(day.modifiers)) continue
        if (priority < 4 && sameRef(focused, day)) [found, priority] = [day, 4]
        else if (priority < 3 && sameRef(lastFocused, day)) [found, priority] = [day, 3]
        else if (priority < 2 && this.isSelected(day.date)) [found, priority] = [day, 2]
        else if (priority < 1 && day.modifiers.today) [found, priority] = [day, 1]
        else if (priority < 0) [found, priority] = [day, 0]
      }
    }
    return found
  }

  /** Each month's days, with their base modifiers. */
  @cached
  get grid(): { date: Date; displayMonth: Date; modifiers: CalendarModifiers }[][] {
    return this.displayMonths.map(month =>
      this.#daysOf(month).map(date => ({
        date,
        displayMonth: month,
        modifiers: this.#baseModifiers(date, month),
      })),
    )
  }

  /** The column headings, from the first day of the week. */
  @cached
  get weekdays(): CalendarWeekday[] {
    const locale = this.locale
    const { formatWeekdayName } = this.formatters
    const { labelWeekday } = this.labels
    const start = startOfWeek(this.today, this.weekStartsOn)
    return Array.from({ length: 7 }, (_, index) => {
      const day = addDays(start, index)
      return {
        key: String(day.getDay()),
        name: formatWeekdayName(day, locale),
        label: labelWeekday(day, locale),
      }
    })
  }

  /** The months shown, each with its caption, dropdowns, weeks and days. */
  @cached
  get months(): CalendarMonth[] {
    const args = this.#args()
    const system = this.system
    const locale = this.locale
    const formatters = this.formatters
    const labels = this.labels
    const classNames = this.classNames
    const custom = args.modifiersClassNames ?? {}
    const grid = this.grid
    const target = this.#focusTargetOf(grid, this.focused, this.lastFocused)
    const interactive = this.isInteractive
    const selected = this.selected
    const range = isRange(selected) ? selected : undefined
    const weekStartsOn = this.weekStartsOn
    const firstWeekContainsDate = this.firstWeekContainsDate
    const [start, end] = this.navBounds
    const years = this.#yearOptions()

    return this.displayMonths.map((month, index) => {
      const days = grid[index]!.map(({ date, displayMonth, modifiers: base }): CalendarDay => {
        const modifiers: CalendarModifiers = { ...base }
        modifiers.focused = !modifiers.hidden && sameRef(this.focused, { date, displayMonth })
        modifiers.selected = this.isSelected(date) || Boolean(base.selected)
        if (range) {
          modifiers.range_start = Boolean(range.from && range.to && isSameDay(date, range.from))
          modifiers.range_end = Boolean(range.from && range.to && isSameDay(date, range.to))
          modifiers.range_middle = rangeIncludesDate(range, date, true)
        }
        const classes = [classNames.day]
        for (const [name, active] of Object.entries(modifiers)) {
          if (!active) continue
          const className = custom[name] ?? classNames[name as keyof CalendarClassNames]
          if (className) classes.push(className)
        }
        const iso = isoDate(date)
        const outside = modifiers.outside
        return {
          key: `${iso}_${isoDate(displayMonth)}`,
          iso,
          date,
          displayMonth,
          outside,
          modifiers,
          label: formatters.formatDay(date, locale),
          buttonLabel: labels.labelDayButton(date, modifiers, locale),
          cellLabel:
            !interactive && !modifiers.hidden
              ? labels.labelGridcell(date, modifiers, locale)
              : undefined,
          isButton: interactive && !modifiers.hidden,
          isShown: !modifiers.hidden,
          tabIndex: target && sameRef(target, { date, displayMonth }) ? 0 : -1,
          localeDate: date.toLocaleDateString(locale.tag),
          outsideMonth: outside ? isoMonth(date) : undefined,
          className: classes.join(' '),
          selectedSingle:
            modifiers.selected &&
            !modifiers.range_start &&
            !modifiers.range_end &&
            !modifiers.range_middle,
        }
      })
      const weeks: CalendarWeek[] = []
      for (let at = 0; at < days.length; at += 7) {
        const week = days.slice(at, at + 7)
        const number = weekNumber(week[0]!.date, system, weekStartsOn, firstWeekContainsDate)
        weeks.push({
          key: week[0]!.key,
          number,
          numberText: formatters.formatWeekNumber(number, locale),
          numberLabel: labels.labelWeekNumber(number, locale),
          days: week,
        })
      }
      const year = system.year(month)
      const monthIndex = system.month(month)
      const withMonths =
        this.captionLayout === 'dropdown' || this.captionLayout === 'dropdown-months'
      const withYears = this.captionLayout === 'dropdown' || this.captionLayout === 'dropdown-years'
      const monthOptions = withMonths
        ? Array.from({ length: system.monthsInYear(year) }, (_, value): CalendarDropdownOption => {
            const option = system.monthStart(year, value)
            return {
              value,
              label: formatters.formatMonthDropdown(option, locale),
              disabled:
                Boolean(start && compareDays(option, system.startOfMonth(start)) < 0) ||
                Boolean(end && compareDays(option, system.startOfMonth(end)) > 0),
              selected: value === monthIndex,
            }
          })
        : undefined
      const yearOptions =
        withYears && years
          ? years.map(option => ({ ...option, selected: option.value === year }))
          : undefined
      return {
        key: isoDate(month),
        index,
        date: month,
        caption: formatters.formatCaption(month, locale),
        gridLabel: labels.labelGrid(month, locale),
        weeks,
        monthOptions,
        yearOptions,
        monthText:
          monthOptions?.find(option => option.selected)?.label ??
          formatters.formatMonthDropdown(month, locale),
        yearText:
          yearOptions?.find(option => option.selected)?.label ??
          formatters.formatYearDropdown(month, locale),
      }
    })
  }

  /** The year dropdown's options: every year between the bounds, when there are both. */
  #yearOptions(): Omit<CalendarDropdownOption, 'selected'>[] | undefined {
    const [start, end] = this.navBounds
    if (!start || !end) return undefined
    const system = this.system
    const locale = this.locale
    const { formatYearDropdown } = this.formatters
    const options: Omit<CalendarDropdownOption, 'selected'>[] = []
    for (let year = system.year(start); year <= system.year(end); year += 1) {
      options.push({
        value: year,
        label: formatYearDropdown(system.monthStart(year, 0), locale),
        disabled: false,
      })
    }
    return options
  }

  /** The day after a move, skipping disabled and hidden days, as react-day-picker's. */
  #nextFocus(by: MoveBy, direction: MoveDirection, from: Date, attempt = 0): Date | undefined {
    if (attempt > 365) return undefined
    const system = this.system
    const step = direction === 'after' ? 1 : -1
    const weekStartsOn = this.weekStartsOn
    let next: Date
    switch (by) {
      case 'day':
        next = addDays(from, step)
        break
      case 'week':
        next = addDays(from, step * 7)
        break
      case 'month':
        next = system.addMonths(from, step)
        break
      case 'year':
        next = system.addYears(from, step)
        break
      case 'startOfWeek':
        next = startOfWeek(from, weekStartsOn)
        break
      case 'endOfWeek':
        next = endOfWeek(from, weekStartsOn)
        break
    }
    const [start, end] = this.navBounds
    if (direction === 'before' && start && compareDays(next, start) < 0) next = start
    if (direction === 'after' && end && compareDays(next, end) > 0) next = end
    const { disabled, hidden } = this.#args()
    if (!isMatch(next, disabled) && !isMatch(next, hidden)) return next
    return this.#nextFocus(by, direction, next, attempt + 1)
  }

  /** Moves focus from the focused day, showing the month it lands in if it isn't shown. */
  moveFocus(by: MoveBy, direction: MoveDirection): void {
    const focused = this.focused
    if (!focused) return
    const next = this.#nextFocus(by, direction, focused.date)
    if (!next) return
    const displayMonth = this.system.startOfMonth(next)
    if (!this.displayMonths.some(month => isSameDay(month, displayMonth))) {
      // With @disableNavigation the month can't change, so focus stays where it is.
      if (this.#args().disableNavigation) return
      this.goToMonth(next)
    }
    this.focused = { date: next, displayMonth }
  }

  // ---------------------------------------------------------------------------------------------
  // Events on a day's button

  clickDay = (day: CalendarDay, event: MouseEvent): void => {
    event.preventDefault()
    event.stopPropagation()
    if (!sameRef(this.focused, day))
      this.focused = { date: day.date, displayMonth: day.displayMonth }
    if (this.#args().mode) this.select(day.date, day.modifiers, event)
    this.#args().onDayClick?.(day.date, day.modifiers, event)
  }

  focusDay = (day: CalendarDay): void => {
    if (!sameRef(this.focused, day))
      this.focused = { date: day.date, displayMonth: day.displayMonth }
  }

  /**
   * Forgets the focused day once focus has left the calendar's days (not when it moves from one
   * day to another, which the arrow keys do). It waits a microtask, so a button that is removed
   * while it has focus doesn't change state mid-render.
   */
  blurDay = (day: CalendarDay, event: FocusEvent): void => {
    const next = event.relatedTarget
    if (next instanceof Element && this.#root?.contains(next) && next.matches('button[data-day]')) {
      return
    }
    queueMicrotask(() => {
      const active = this.#root?.ownerDocument.activeElement
      if (active && this.#root?.contains(active) && active.matches('button[data-day]')) return
      if (!sameRef(this.focused, day)) return
      this.lastFocused = this.focused
      this.focused = undefined
    })
  }

  keyDay = (_day: CalendarDay, event: KeyboardEvent): void => {
    const map = KEYS[event.key]
    if (!map) return
    event.preventDefault()
    event.stopPropagation()
    const rtl = getDirection(event.currentTarget as Element, this.#args().dir) === 'rtl'
    const [by, direction] = map(event.shiftKey, rtl)
    this.moveFocus(by, direction)
  }

  /** Put it on the root: the calendar keeps its element, for focus. */
  root = modifier((element: HTMLElement) => {
    this.#root = element
    return () => {
      if (this.#root === element) this.#root = undefined
    }
  })

  /**
   * Put it on each day's button with its `focused` modifier: it takes focus when that's set, once
   * the render is over. Focusing fires the days' blur and focus handlers, which read their day;
   * run inside the modifier, those reads would count as the modifier's, and on Ember 6.12 the next
   * render, which updates those days, would then assert that they were read before they changed
   * (when focus moves to an earlier week, whose modifiers render first).
   */
  focusWhen = modifier((element: HTMLElement, [focused]: [boolean]) => {
    if (!focused) return
    queueMicrotask(() => {
      if (element.isConnected && element.ownerDocument.activeElement !== element) element.focus()
    })
  })
}
