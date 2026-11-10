import type { TOC } from '@ember/component/template-only'
import { on } from '@ember/modifier'
import { modifier } from 'ember-modifier'
import PowerCalendarDays from 'ember-power-calendar/components/power-calendar/days'
import PowerCalendarMultipleDays from 'ember-power-calendar/components/power-calendar-multiple/days'
import PowerCalendarRangeDays from 'ember-power-calendar/components/power-calendar-range/days'
import {
  add,
  diff,
  endOf,
  endOfWeek,
  formatDate,
  isAfter,
  isBefore,
  isSame,
  startOf,
  startOfWeek,
  type PowerCalendarDay,
} from 'ember-power-calendar/utils'
import { getDirection } from '@ember-joinery/primitives/direction'

/*
 * The day grid of Joinery's calendars: ember-power-calendar's own Days components (which build
 * the days, mark them selected, disabled, today or outside the month, and track focus),
 * subclassed to draw shadcn's Calendar instead of their markup, with WAI-ARIA's date grid
 * keyboard (arrow keys flipped right to left, Home and End, Page Up and Page Down) and a tab stop
 * on the selected day, else today, else the month's first enabled day.
 */

/** `ddd` names, which `@disabledDates` may hold, as ember-power-calendar compares them. */
const WEEK_DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

/** One day as the grid draws it. */
export interface GridCell {
  /** `YYYY-MM-DD`, ember-power-calendar's id for the day (its `data-date`). */
  id: string
  number: number
  /** The day's accessible name: the full date in the calendar's locale. */
  label: string
  /** Upstream's `data-day`: the date in the locale's short form. */
  day: string
  hidden: boolean
  outside: boolean
  today: boolean
  selected: boolean
  disabled: boolean
  rangeStart: boolean
  rangeEnd: boolean
  rangeMiddle: boolean
  selectedSingle: boolean
  tabindex: '0' | '-1'
}

/** A row of the grid: its days, keyed by the first one's id so re-renders keep the row. */
export interface GridWeek {
  id: string
  days: GridCell[]
}

export interface WeekdayHeader {
  short: string
  long: string
}

/** What the grid's template reads from the Days component that draws it. */
export interface GridHost {
  readonly weekRows: GridWeek[]
  readonly weekdayHeaders: WeekdayHeader[]
  readonly captionId: string
  readonly calendarId: string
  readonly multiselectable: boolean
  readonly setup: PowerCalendarDays['setup']
  handleClick(event: MouseEvent): void
  handleDayFocus(event: FocusEvent): void
  handleDayBlur(): void
  onKeyDown: (event: KeyboardEvent) => void
  /** The day the keyboard moved to, focused once the grid has drawn it. */
  pendingFocus: string | null
  focusedId: string | null
  readonly currentCenter: Date
}

interface CalendarLike {
  uniqueId: string
  calendarUniqueId?: string
  center: Date
  locale: string
  type: 'single' | 'range' | 'multiple'
  actions: {
    select?: unknown
    changeCenter?: (center: Date, calendar: never, event: Event) => PromiseLike<void>
  }
}

/** What the keyboard and the cells read from a Days component, whichever kind it is. */
interface DaysLike {
  readonly days: PowerCalendarDay[]
  focusedId: string | null
  pendingFocus: string | null
  element: HTMLElement | undefined
  readonly localeStartOfWeek: number
  readonly currentCenter: Date
  readonly showDaysAround: boolean
  readonly args: {
    calendar: CalendarLike
    minDate?: Date
    maxDate?: Date
    disabledDates?: Array<Date | string>
  }
  isDisabledDate(date: Date): boolean
}

const fullDates = new Map<string, Intl.DateTimeFormat>()
const shortDates = new Map<string, Intl.DateTimeFormat>()

function formatter(
  cache: Map<string, Intl.DateTimeFormat>,
  locale: string,
  style: 'full' | 'short',
) {
  let found = cache.get(locale)
  if (!found) {
    try {
      found = new Intl.DateTimeFormat(locale || undefined, { dateStyle: style })
    } catch {
      found = new Intl.DateTimeFormat(undefined, { dateStyle: style })
    }
    cache.set(locale, found)
  }
  return found
}

/** ember-power-calendar's test for a disabled day, from its public date utilities. */
function baseDisabled(host: DaysLike, date: Date): boolean {
  const { calendar, minDate, maxDate, disabledDates } = host.args
  if (!calendar.actions.select) return true
  if (minDate && isBefore(date, startOf(minDate, 'day'))) return true
  if (maxDate && isAfter(date, endOf(maxDate, 'day'))) return true
  return Boolean(
    disabledDates?.some(
      d =>
        (d instanceof Date && isSame(date, d, 'day')) ||
        (typeof d === 'string' && WEEK_DAYS.includes(d) && formatDate(date, 'ddd') === d),
    ),
  )
}

/** The grid's cells, a week to a row, with the tab stop on one day. */
function cellsOf(host: DaysLike): GridWeek[] {
  const { calendar } = host.args
  const days = host.days
  const range = calendar.type === 'range'
  const stop = tabStopOf(host)
  const locale = calendar.locale
  const full = formatter(fullDates, locale, 'full')
  const short = formatter(shortDates, locale, 'short')
  const cells = days.map((day): GridCell => {
    const rangeStart = Boolean(range && day.isRangeStart)
    const rangeEnd = Boolean(range && day.isRangeEnd)
    const rangeMiddle = range && day.isSelected && !rangeStart && !rangeEnd
    return {
      id: day.id,
      number: day.number,
      label: full.format(day.date),
      day: short.format(day.date),
      hidden: !day.isCurrentMonth && !host.showDaysAround,
      outside: !day.isCurrentMonth,
      today: day.isToday,
      selected: day.isSelected,
      disabled: day.isDisabled,
      rangeStart,
      rangeEnd,
      rangeMiddle,
      selectedSingle: day.isSelected && !rangeStart && !rangeEnd && !rangeMiddle,
      tabindex: day.id === stop ? '0' : '-1',
    }
  })
  const weeks: GridWeek[] = []
  for (let i = 0; i < cells.length; i += 7) {
    const days = cells.slice(i, i + 7)
    weeks.push({ id: `week-of-${days[0]?.id}`, days })
  }
  return weeks
}

/**
 * The one day Tab reaches: the focused day, else the first selected day of the month, else
 * today, else the month's first day that can be chosen.
 */
function tabStopOf(host: DaysLike): string | undefined {
  const days = host.days
  const focused = days.find(day => day.id === host.focusedId && !day.isDisabled)
  if (focused && (focused.isCurrentMonth || host.showDaysAround)) return focused.id
  const month = days.filter(day => day.isCurrentMonth && !day.isDisabled)
  return (month.find(day => day.isSelected) ?? month.find(day => day.isToday) ?? month[0])?.id
}

function weekdayHeadersOf(
  host: DaysLike & { weekdaysNames: string[]; weekdays: string[] },
): WeekdayHeader[] {
  const start = host.localeStartOfWeek
  const long = host.weekdays.slice(start).concat(host.weekdays.slice(0, start))
  return host.weekdaysNames.map((short, i) => ({ short, long: long[i] ?? short }))
}

function monthIndex(date: Date): number {
  return date.getFullYear() * 12 + date.getMonth()
}

/** How far a key moves focus from a day, or `undefined` for a key the grid doesn't use. */
function moveFor(event: KeyboardEvent, rtl: boolean): ((date: Date) => Date) | undefined {
  const back = rtl ? 1 : -1
  switch (event.key) {
    case 'ArrowLeft':
      return date => add(date, back, 'day')
    case 'ArrowRight':
      return date => add(date, -back, 'day')
    case 'ArrowUp':
      return date => add(date, -7, 'day')
    case 'ArrowDown':
      return date => add(date, 7, 'day')
    case 'PageUp':
      return date => add(date, -1, event.shiftKey ? 'year' : 'month')
    case 'PageDown':
      return date => add(date, 1, event.shiftKey ? 'year' : 'month')
    default:
      return undefined
  }
}

/** The furthest a key looks for a day that can be chosen, past disabled ones. */
const SEARCH_LIMIT = 366

/**
 * Moves focus as WAI-ARIA's date grid does: the arrow keys by a day or a week (left and right
 * flipped right to left), Home and End to the week's first and last day, Page Up and Page Down
 * by a month (with Shift, a year), each past days that can't be chosen, and to another month
 * when the day is in one.
 */
async function moveFocus(host: DaysLike, event: KeyboardEvent): Promise<void> {
  if (event.altKey || event.ctrlKey || event.metaKey) return
  const current = host.days.find(day => day.id === host.focusedId)?.date
  if (!current) return
  const rtl = getDirection(host.element ?? null) === 'rtl'
  let target: Date | undefined
  if (event.key === 'Home' || event.key === 'End') {
    const first = startOfWeek(current, host.localeStartOfWeek)
    const last = endOfWeek(current, host.localeStartOfWeek)
    const forward = event.key === 'Home'
    for (
      let day = startOf(forward ? first : last, 'day');
      forward ? !isAfter(day, current) : !isBefore(day, current);
      day = add(day, forward ? 1 : -1, 'day')
    ) {
      if (!host.isDisabledDate(day)) {
        target = day
        break
      }
    }
  } else {
    const move = moveFor(event, rtl)
    if (!move) return
    let day = move(current)
    for (let i = 0; i < SEARCH_LIMIT; i++) {
      if (!host.isDisabledDate(day)) {
        target = day
        break
      }
      if (outOfBounds(host, day)) break
      day = move(day)
    }
  }
  event.preventDefault()
  if (!target) return
  await focusDay(host, target, event)
}

/** Whether a day is past `@minDate` or `@maxDate`, so looking further that way finds nothing. */
function outOfBounds(host: DaysLike, date: Date): boolean {
  const { minDate, maxDate } = host.args
  return Boolean(
    (minDate && isBefore(date, startOf(minDate, 'day'))) ||
    (maxDate && isAfter(date, endOf(maxDate, 'day'))),
  )
}

/** Shows the day's month, if it isn't shown, and focuses the day once the grid has drawn it. */
async function focusDay(host: DaysLike, date: Date, event: Event): Promise<void> {
  const { calendar } = host.args
  if (monthIndex(date) !== monthIndex(host.currentCenter)) {
    const changeCenter = calendar.actions.changeCenter
    if (!changeCenter) return
    await changeCenter(date, calendar as never, event)
  }
  const id = formatDate(date, 'YYYY-MM-DD')
  host.pendingFocus = id
  host.focusedId = id
}

/**
 * Focuses the day the keyboard moved to once the grid has drawn it. A modifier runs after the
 * render's DOM changes, the keyed weeks' moves among them, which would take focus off a day
 * moved while focused; it runs again whenever the focused day or the month changes.
 */
const focusPending = modifier(
  (grid: HTMLElement, [host, focusedId, center]: [GridHost, string | null, Date]) => {
    // Read them, so the modifier runs again as they change.
    void focusedId
    void center
    const id = host.pendingFocus
    if (!id) return
    const day = grid.querySelector<HTMLElement>(`[data-date="${id}"]`)
    if (!day) return
    host.pendingFocus = null
    day.focus()
  },
)

export interface DayGridSignature {
  Args: { host: GridHost }
  Element: HTMLDivElement
}

/**
 * shadcn's month grid, as WAI-ARIA's grid: a row of weekday headers, then a row a week, each
 * day a ghost Button that is the grid's cell (`role="gridcell"`, `aria-selected`), named by its
 * full date, with `aria-current="date"` on today. The wrapper around each day carries upstream's
 * day state (`data-selected`, `data-today`, `data-outside`, `data-range-*`) for the styles.
 */
export const DayGrid: TOC<DayGridSignature> = <template>
  {{! template-lint-disable no-invalid-interactive }}
  <div
    class="jn-power-calendar-grid"
    role="grid"
    aria-labelledby={{@host.captionId}}
    aria-multiselectable={{if @host.multiselectable "true"}}
    data-slot="calendar-grid"
    data-power-calendar-id={{@host.calendarId}}
    data-test-jn-part="grid"
    {{on "click" @host.handleClick}}
    {{on "keydown" @host.onKeyDown}}
    {{@host.setup}}
    {{focusPending @host @host.focusedId @host.currentCenter}}
    ...attributes
  >
    <div class="jn-power-calendar-weekdays" role="row">
      {{#each @host.weekdayHeaders as |weekday|}}
        <div
          class="jn-power-calendar-weekday"
          role="columnheader"
          aria-label={{weekday.long}}
          data-test-jn-part="weekday"
        >{{weekday.short}}</div>
      {{/each}}
    </div>
    {{#each @host.weekRows key="id" as |week|}}
      <div class="jn-power-calendar-week" role="row" data-test-jn-part="week">
        {{#each week.days key="id" as |cell|}}
          {{#if cell.hidden}}
            <div class="jn-power-calendar-day" role="gridcell" data-hidden="true"></div>
          {{else}}
            <div
              class="jn-power-calendar-day group/day"
              data-day={{cell.day}}
              data-selected={{if cell.selected "true"}}
              data-today={{if cell.today "true"}}
              data-outside={{if cell.outside "true"}}
              data-disabled={{if cell.disabled "true"}}
              data-range-start={{if cell.rangeStart "true"}}
              data-range-middle={{if cell.rangeMiddle "true"}}
              data-range-end={{if cell.rangeEnd "true"}}
            >
              <button
                type="button"
                role="gridcell"
                class="jn-button group/button jn-button-variant-ghost jn-button-size-icon jn-calendar-day-button jn-power-calendar-day-button"
                data-slot="button"
                data-variant="ghost"
                data-size="icon"
                data-date={{cell.id}}
                data-day={{cell.day}}
                data-selected-single={{if cell.selectedSingle "true" "false"}}
                data-range-start={{if cell.rangeStart "true" "false"}}
                data-range-end={{if cell.rangeEnd "true" "false"}}
                data-range-middle={{if cell.rangeMiddle "true" "false"}}
                data-test-jn-part="day"
                data-test-jn-value={{cell.id}}
                aria-label={{cell.label}}
                aria-selected={{if cell.selected "true" "false"}}
                aria-current={{if cell.today "date"}}
                disabled={{cell.disabled}}
                tabindex={{cell.tabindex}}
                {{on "focus" @host.handleDayFocus}}
                {{on "blur" @host.handleDayBlur}}
              >{{cell.number}}</button>
            </div>
          {{/if}}
        {{/each}}
      </div>
    {{/each}}
  </div>
</template>

/** The caption's id, which names the grid. */
function captionIdOf(calendar: CalendarLike): string {
  return `${calendar.calendarUniqueId ?? calendar.uniqueId}-caption`
}

/** The Days of a calendar that chooses one day. */
export class SingleDays extends PowerCalendarDays implements GridHost {
  pendingFocus: string | null = null

  get weekRows(): GridWeek[] {
    return cellsOf(this as unknown as DaysLike)
  }

  get weekdayHeaders(): WeekdayHeader[] {
    return weekdayHeadersOf(this as unknown as DaysLike & SingleDays)
  }

  get captionId(): string {
    return captionIdOf(this.args.calendar as unknown as CalendarLike)
  }

  get calendarId(): string {
    const { calendar } = this.args
    return calendar.calendarUniqueId ?? calendar.uniqueId
  }

  get multiselectable(): boolean {
    return false
  }

  isDisabledDate(date: Date): boolean {
    return baseDisabled(this as unknown as DaysLike, date)
  }

  onKeyDown = (event: KeyboardEvent): void => {
    void moveFocus(this as unknown as DaysLike, event)
  }

  <template><DayGrid @host={{this}} ...attributes /></template>
}

/** The Days of a calendar that chooses a range: the days between its ends, and its ends. */
export class RangeDays extends PowerCalendarRangeDays implements GridHost {
  pendingFocus: string | null = null

  get weekRows(): GridWeek[] {
    return cellsOf(this as unknown as DaysLike)
  }

  get weekdayHeaders(): WeekdayHeader[] {
    return weekdayHeadersOf(this as unknown as DaysLike & RangeDays)
  }

  get captionId(): string {
    return captionIdOf(this.args.calendar as unknown as CalendarLike)
  }

  get calendarId(): string {
    const { calendar } = this.args
    return calendar.calendarUniqueId ?? calendar.uniqueId
  }

  get multiselectable(): boolean {
    return true
  }

  /**
   * As ember-power-calendar's range days are: once a start is chosen, a day closer to it than
   * `@minRange` or further than `@maxRange` can't be the end.
   */
  isDisabledDate(date: Date): boolean {
    if (baseDisabled(this as unknown as DaysLike, date)) return true
    const { selected, minRange, maxRange } = this.args.calendar
    const start = selected?.start
    if (!start || selected?.end) return false
    const distance = Math.abs(diff(date, start))
    return Boolean(
      (minRange && distance < minRange) ||
      (maxRange !== null && maxRange !== undefined && distance > maxRange),
    )
  }

  onKeyDown = (event: KeyboardEvent): void => {
    void moveFocus(this as unknown as DaysLike, event)
  }

  <template><DayGrid @host={{this}} ...attributes /></template>
}

/** The Days of a calendar that chooses several days, up to `@maxLength`. */
export class MultipleDays extends PowerCalendarMultipleDays implements GridHost {
  pendingFocus: string | null = null

  get weekRows(): GridWeek[] {
    return cellsOf(this as unknown as DaysLike)
  }

  get weekdayHeaders(): WeekdayHeader[] {
    return weekdayHeadersOf(this as unknown as DaysLike & MultipleDays)
  }

  get captionId(): string {
    return captionIdOf(this.args.calendar as unknown as CalendarLike)
  }

  get calendarId(): string {
    const { calendar } = this.args
    return calendar.calendarUniqueId ?? calendar.uniqueId
  }

  get multiselectable(): boolean {
    return true
  }

  /** As ember-power-calendar's are: with `@maxLength` days chosen, only those can be pressed. */
  isDisabledDate(date: Date): boolean {
    if (baseDisabled(this as unknown as DaysLike, date)) return true
    const selected = this.args.calendar.selected ?? []
    return selected.length >= this.maxLength && !selected.some(d => isSame(date, d, 'day'))
  }

  onKeyDown = (event: KeyboardEvent): void => {
    void moveFocus(this as unknown as DaysLike, event)
  }

  <template><DayGrid @host={{this}} ...attributes /></template>
}
