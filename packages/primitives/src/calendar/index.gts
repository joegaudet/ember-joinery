import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { visuallyHidden } from '../visually-hidden.gts'
import {
  CalendarState,
  type CalendarArgs,
  type CalendarClassNames,
  type CalendarDay,
} from './state.ts'

export {
  CalendarState,
  defaultCalendarClassNames,
  defaultCalendarFormatters,
  defaultCalendarLabels,
} from './state.ts'
export type {
  CalendarArgs,
  CalendarClassNames,
  CalendarDay,
  CalendarDropdownOption,
  CalendarFormatters,
  CalendarLabels,
  CalendarModifiers,
  CalendarMode,
  CalendarMonth,
  CalendarSelectDetails,
  CalendarValue,
  CalendarWeek,
  CalendarWeekday,
  CaptionLayout,
} from './state.ts'
export {
  addDays,
  addToRange,
  calendarLocale,
  calendarSystem,
  isMatch,
  isSameDay,
  isoDate,
  parseIsoDate,
  rangeIncludesDate,
  startOfDay,
  weekInfo,
} from './dates.ts'
export type {
  CalendarLocale,
  CalendarSystem,
  DateAfter,
  DateBefore,
  DateInterval,
  DateRange,
  DayOfWeek,
  DayOfWeekNumber,
  Matcher,
  WeekInfo,
} from './dates.ts'

/** Which way a chevron points: back, forward, or down (a dropdown's). */
export type ChevronOrientation = 'left' | 'right' | 'down'

export interface CalendarSignature {
  Args: CalendarArgs & {
    /**
     * A class for each part and state, as react-day-picker's `classNames`; each replaces that
     * part's `rdp-<part>`.
     */
    classNames?: Partial<CalendarClassNames>
    /** Its name, for `CalendarHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** A chevron of your own, in place of the default: which way it points, and its class. */
    chevron: [orientation: ChevronOrientation, className: string]
    /** What a day's button shows, in place of its number (`day.label`). */
    day: [day: CalendarDay]
  }
  Element: HTMLDivElement
}

const isLeft = (orientation: ChevronOrientation) => orientation === 'left'
const isRight = (orientation: ChevronOrientation) => orientation === 'right'
const flag = (value: boolean | undefined) => (value ? 'true' : undefined)
const bool = (value: boolean) => (value ? 'true' : 'false')
const join = (...classes: (string | undefined)[]) => classes.filter(Boolean).join(' ')

/**
 * A calendar's chevron, react-day-picker's own: the default where no `<:chevron>` block is given.
 */
const Chevron: TOC<{ Args: { orientation: ChevronOrientation; class: string } }> = <template>
  <svg class={{@class}} width="24" height="24" viewBox="0 0 24 24" aria-hidden="true">
    {{#if (isLeft @orientation)}}
      <polygon points="16 18.112 9.81111111 12 16 5.87733333 14.0888889 4 6 12 14.0888889 20" />
    {{else if (isRight @orientation)}}
      <polygon points="8 18.112 14.18888889 12 8 5.87733333 9.91111111 4 18 12 9.91111111 20" />
    {{else}}
      <polygon points="6.77 8 12.5 13.57 18.24 8 20 9.72 12.5 17 5 9.72" />
    {{/if}}
  </svg>
</template>

/**
 * A calendar, headless: react-day-picker's `DayPicker`, which Joinery's `<Calendar>` replaces.
 * It renders react-day-picker's markup (a grid for each month, with its caption and weekday
 * names, and a button for each day) with react-day-picker's `rdp-*` classes, or yours
 * (`@classNames`), and no styles; the styled `<Calendar>` in `@ember-joinery/ember` renders the
 * same from the same `CalendarState`, in shadcn's style.
 *
 *   <Calendar @mode="single" @value={{this.date}} @onValueChange={{this.setDate}} />
 *   <Calendar @mode="range" @numberOfMonths={{2}} @disabled={{this.isPast}} />
 *
 * Dates go in and out as `Date`s, a range as `{ from, to }`, and every name and number comes
 * from Intl in `@locale`, so there is no date library. The days are a grid: one is in the tab
 * order, and the arrow keys, Page Up and Down, Home and End move between them.
 */
export class Calendar extends Component<CalendarSignature> {
  state = new CalendarState(
    () => this.args,
    () => this.args.classNames,
  )

  get cls(): CalendarClassNames {
    return this.state.classNames
  }

  get rootClass(): string {
    return this.cls.root
  }

  get requiredAttribute(): string | undefined {
    const required = this.args.required
    return required === undefined ? undefined : bool(required)
  }

  get navLabel(): string | undefined {
    return this.state.labels.labelNav(this.state.locale) || undefined
  }

  get previousLabel(): string {
    return this.state.labels.labelPrevious(this.state.previousMonth, this.state.locale)
  }

  get nextLabel(): string {
    return this.state.labels.labelNext(this.state.nextMonth, this.state.locale)
  }

  get monthDropdownLabel(): string {
    return this.state.labels.labelMonthDropdown(this.state.locale)
  }

  get yearDropdownLabel(): string {
    return this.state.labels.labelYearDropdown(this.state.locale)
  }

  get weekNumberHeaderLabel(): string {
    return this.state.labels.labelWeekNumberHeader(this.state.locale)
  }

  get weekNumberHeader(): string {
    return this.state.formatters.formatWeekNumberHeader(this.state.locale)
  }

  get multipleMonths(): string | undefined {
    return flag(this.state.numberOfMonths > 1)
  }

  get previousDisabled(): boolean {
    return !this.state.previousMonth
  }

  get nextDisabled(): boolean {
    return !this.state.nextMonth
  }

  dropdownClass = (part: 'months_dropdown' | 'years_dropdown'): string =>
    join(this.cls.dropdown, this.cls[part])

  <template>
    <div
      class={{this.rootClass}}
      dir={{@dir}}
      data-mode={{@mode}}
      data-required={{this.requiredAttribute}}
      data-multiple-months={{this.multipleMonths}}
      data-week-numbers={{flag @showWeekNumber}}
      data-test-jn="calendar"
      data-test-jn-name={{@name}}
      {{this.state.root}}
      ...attributes
    >
      <div class={{this.cls.months}}>
        {{#unless @hideNavigation}}
          <nav class={{this.cls.nav}} aria-label={{this.navLabel}} data-test-jn-part="nav">
            <button
              type="button"
              class={{this.cls.button_previous}}
              tabindex={{if this.previousDisabled "-1"}}
              aria-disabled={{flag this.previousDisabled}}
              aria-label={{this.previousLabel}}
              data-test-jn-part="previous"
              {{on "click" this.state.goToPrevious}}
            >
              {{#if (has-block "chevron")}}
                {{yield "left" this.cls.chevron to="chevron"}}
              {{else}}
                <Chevron @orientation="left" @class={{this.cls.chevron}} />
              {{/if}}
            </button>
            <button
              type="button"
              class={{this.cls.button_next}}
              tabindex={{if this.nextDisabled "-1"}}
              aria-disabled={{flag this.nextDisabled}}
              aria-label={{this.nextLabel}}
              data-test-jn-part="next"
              {{on "click" this.state.goToNext}}
            >
              {{#if (has-block "chevron")}}
                {{yield "right" this.cls.chevron to="chevron"}}
              {{else}}
                <Chevron @orientation="right" @class={{this.cls.chevron}} />
              {{/if}}
            </button>
          </nav>
        {{/unless}}
        {{#each this.state.months key="key" as |month|}}
          <div class={{this.cls.month}} data-test-jn-part="month" data-test-jn-value={{month.key}}>
            <div class={{this.cls.month_caption}}>
              {{#if this.state.hasDropdowns}}
                <div class={{this.cls.dropdowns}}>
                  {{#if month.monthOptions}}
                    <span
                      data-disabled={{flag @disableNavigation}}
                      class={{this.cls.dropdown_root}}
                    >
                      <select
                        class={{this.dropdownClass "months_dropdown"}}
                        aria-label={{this.monthDropdownLabel}}
                        disabled={{@disableNavigation}}
                        data-test-jn-part="month-dropdown"
                        {{on "change" (fn this.state.changeMonth month)}}
                      >
                        {{#each month.monthOptions as |choice|}}
                          <option
                            value={{choice.value}}
                            disabled={{choice.disabled}}
                            selected={{choice.selected}}
                          >{{choice.label}}</option>
                        {{/each}}
                      </select>
                      <span class={{this.cls.caption_label}} aria-hidden="true">
                        {{month.monthText}}
                        {{#if (has-block "chevron")}}
                          {{yield "down" this.cls.chevron to="chevron"}}
                        {{else}}
                          <Chevron @orientation="down" @class={{this.cls.chevron}} />
                        {{/if}}
                      </span>
                    </span>
                  {{else}}
                    <span>{{month.monthText}}</span>
                  {{/if}}
                  {{#if month.yearOptions}}
                    <span
                      data-disabled={{flag @disableNavigation}}
                      class={{this.cls.dropdown_root}}
                    >
                      <select
                        class={{this.dropdownClass "years_dropdown"}}
                        aria-label={{this.yearDropdownLabel}}
                        disabled={{@disableNavigation}}
                        data-test-jn-part="year-dropdown"
                        {{on "change" (fn this.state.changeYear month)}}
                      >
                        {{#each month.yearOptions as |choice|}}
                          <option
                            value={{choice.value}}
                            disabled={{choice.disabled}}
                            selected={{choice.selected}}
                          >{{choice.label}}</option>
                        {{/each}}
                      </select>
                      <span class={{this.cls.caption_label}} aria-hidden="true">
                        {{month.yearText}}
                        {{#if (has-block "chevron")}}
                          {{yield "down" this.cls.chevron to="chevron"}}
                        {{else}}
                          <Chevron @orientation="down" @class={{this.cls.chevron}} />
                        {{/if}}
                      </span>
                    </span>
                  {{else}}
                    <span>{{month.yearText}}</span>
                  {{/if}}
                  <span
                    role="status"
                    aria-live="polite"
                    data-test-jn-part="caption"
                    {{visuallyHidden}}
                  >
                    {{month.caption}}
                  </span>
                </div>
              {{else}}
                <span
                  class={{this.cls.caption_label}}
                  role="status"
                  aria-live="polite"
                  data-test-jn-part="caption"
                >{{month.caption}}</span>
              {{/if}}
            </div>
            <table
              role="grid"
              aria-multiselectable={{bool this.state.isMultiselectable}}
              aria-label={{month.gridLabel}}
              class={{this.cls.month_grid}}
              data-test-jn-part="grid"
            >
              {{#unless @hideWeekdays}}
                <thead aria-hidden="true">
                  <tr class={{this.cls.weekdays}}>
                    {{#if @showWeekNumber}}
                      <th
                        aria-label={{this.weekNumberHeaderLabel}}
                        class={{this.cls.week_number_header}}
                        scope="col"
                      >{{this.weekNumberHeader}}</th>
                    {{/if}}
                    {{#each this.state.weekdays key="key" as |weekday|}}
                      <th
                        aria-label={{weekday.label}}
                        class={{this.cls.weekday}}
                        scope="col"
                        data-test-jn-part="weekday"
                      >{{weekday.name}}</th>
                    {{/each}}
                  </tr>
                </thead>
              {{/unless}}
              <tbody class={{this.cls.weeks}}>
                {{#each month.weeks key="key" as |week|}}
                  <tr class={{this.cls.week}} data-test-jn-part="week">
                    {{#if @showWeekNumber}}
                      <th
                        aria-label={{week.numberLabel}}
                        class={{this.cls.week_number}}
                        scope="row"
                        role="rowheader"
                        data-test-jn-part="week-number"
                      >{{week.numberText}}</th>
                    {{/if}}
                    {{#each week.days key="key" as |day|}}
                      <td
                        class={{day.className}}
                        role="gridcell"
                        aria-selected={{flag day.modifiers.selected}}
                        aria-label={{day.cellLabel}}
                        data-day={{day.iso}}
                        data-month={{day.outsideMonth}}
                        data-selected={{flag day.modifiers.selected}}
                        data-disabled={{flag day.modifiers.disabled}}
                        data-hidden={{flag day.modifiers.hidden}}
                        data-outside={{flag day.outside}}
                        data-focused={{flag day.modifiers.focused}}
                        data-today={{flag day.modifiers.today}}
                        data-test-jn-part="day"
                        data-test-jn-value={{day.iso}}
                      >
                        {{#if day.isButton}}
                          <button
                            type="button"
                            class={{this.cls.day_button}}
                            disabled={{day.modifiers.disabled}}
                            tabindex={{day.tabIndex}}
                            aria-label={{day.buttonLabel}}
                            data-day={{day.localeDate}}
                            data-selected-single={{bool day.selectedSingle}}
                            data-range-start={{bool day.modifiers.range_start}}
                            data-range-end={{bool day.modifiers.range_end}}
                            data-range-middle={{bool day.modifiers.range_middle}}
                            data-test-jn-part="day-button"
                            data-test-jn-value={{day.iso}}
                            {{on "click" (fn this.state.clickDay day)}}
                            {{on "focus" (fn this.state.focusDay day)}}
                            {{on "blur" (fn this.state.blurDay day)}}
                            {{on "keydown" (fn this.state.keyDay day)}}
                            {{this.state.focusWhen day.modifiers.focused}}
                          >
                            {{#if (has-block "day")}}
                              {{yield day to="day"}}
                            {{else}}
                              {{day.label}}
                            {{/if}}
                          </button>
                        {{else if day.isShown}}
                          {{day.label}}
                        {{/if}}
                      </td>
                    {{/each}}
                  </tr>
                {{/each}}
              </tbody>
            </table>
          </div>
        {{/each}}
      </div>
    </div>
  </template>
}

export default Calendar
