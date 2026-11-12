import Component from '@glimmer/component'
import { cached } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { ChevronDown, ChevronLeft, ChevronRight } from 'lucide'
import {
  CalendarState,
  type CalendarArgs,
  type CalendarDay,
  type CalendarFormatters,
} from '@ember-joinery/primitives/calendar'
import { visuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Icon from './icon.gts'
import { buttonClasses, type ButtonVariant } from './button.gts'

export interface CalendarSignature {
  Args: CalendarArgs & {
    /** The look of the previous and next buttons, as a Button's `@variant`. Default `ghost`. */
    buttonVariant?: ButtonVariant
    /** Its name, for `CalendarHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /**
     * What a day's button shows, in place of its number (`{{day.label}}`): upstream's custom
     * `DayButton`. The day has its `date`, `label`, `outside` and `modifiers`.
     */
    day: [day: CalendarDay]
  }
  Element: HTMLDivElement
}

/** shadcn's month dropdown: the short month name (`Jan`), where react-day-picker's is long. */
const formatMonthDropdown: CalendarFormatters['formatMonthDropdown'] = (month, locale) =>
  locale.format(month, { month: 'short' })

const flag = (value: boolean | undefined) => (value ? 'true' : undefined)
const bool = (value: boolean) => (value ? 'true' : 'false')

/**
 * A calendar to pick a date, several dates or a range: shadcn's Calendar, with Joinery's own
 * date picking in place of react-day-picker (no date library: dates go in and out as `Date`s,
 * and every name and number comes from Intl).
 *
 *   <Calendar @mode="single" @value={{this.date}} @onValueChange={{this.setDate}} class="rounded-lg border" />
 *   <Calendar @mode="range" @numberOfMonths={{2}} @captionLayout="dropdown" />
 *
 * It takes react-day-picker's options as arguments, with upstream's defaults: outside days
 * shown, the caption as a label, and ghost buttons. Its attributes go on the root.
 */
export default class Calendar extends Component<CalendarSignature> {
  /** The arguments the state reads, with upstream's defaults filled in. */
  @cached
  get options(): CalendarArgs {
    const args = { ...this.args }
    return {
      ...args,
      showOutsideDays: args.showOutsideDays ?? true,
      captionLayout: args.captionLayout ?? 'label',
      formatters: { formatMonthDropdown, ...args.formatters },
    }
  }

  state = new CalendarState(() => this.options, undefined, this)

  get navButtonClass(): string {
    return buttonClasses({ variant: this.args.buttonVariant ?? 'ghost' })
  }

  get requiredAttribute(): string | undefined {
    const required = this.args.required
    return required === undefined ? undefined : bool(required)
  }

  get multipleMonths(): string | undefined {
    return flag(this.state.numberOfMonths > 1)
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

  get previousDisabled(): boolean {
    return !this.state.previousMonth
  }

  get nextDisabled(): boolean {
    return !this.state.nextMonth
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

  <template>
    <div
      class="jn-calendar group/calendar rdp-root"
      data-slot="calendar"
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
      <div class="rdp-months">
        {{#unless @hideNavigation}}
          <nav class="rdp-nav" aria-label={{this.navLabel}} data-test-jn-part="nav">
            <button
              type="button"
              class="{{this.navButtonClass}} rdp-button_previous"
              tabindex={{if this.previousDisabled "-1"}}
              aria-disabled={{flag this.previousDisabled}}
              aria-label={{this.previousLabel}}
              data-test-jn-part="previous"
              {{on "click" this.state.goToPrevious}}
            >
              <Icon @icon={{ChevronLeft}} class="jn-rtl-flip jn-size-4 rdp-chevron" />
            </button>
            <button
              type="button"
              class="{{this.navButtonClass}} rdp-button_next"
              tabindex={{if this.nextDisabled "-1"}}
              aria-disabled={{flag this.nextDisabled}}
              aria-label={{this.nextLabel}}
              data-test-jn-part="next"
              {{on "click" this.state.goToNext}}
            >
              <Icon @icon={{ChevronRight}} class="jn-rtl-flip jn-size-4 rdp-chevron" />
            </button>
          </nav>
        {{/unless}}
        {{#each this.state.months key="key" as |month|}}
          <div class="rdp-month" data-test-jn-part="month" data-test-jn-value={{month.key}}>
            <div class="rdp-month_caption">
              {{#if this.state.hasDropdowns}}
                <div class="rdp-dropdowns">
                  {{#if month.monthOptions}}
                    <span data-disabled={{flag @disableNavigation}} class="rdp-dropdown_root">
                      <select
                        class="rdp-dropdown rdp-months_dropdown"
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
                      <span class="rdp-caption_label" aria-hidden="true">{{month.monthText}}<Icon
                          @icon={{ChevronDown}}
                          @size={{18}}
                          class="jn-size-4 rdp-chevron"
                        /></span>
                    </span>
                  {{else}}
                    <span>{{month.monthText}}</span>
                  {{/if}}
                  {{#if month.yearOptions}}
                    <span data-disabled={{flag @disableNavigation}} class="rdp-dropdown_root">
                      <select
                        class="rdp-dropdown rdp-years_dropdown"
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
                      <span class="rdp-caption_label" aria-hidden="true">{{month.yearText}}<Icon
                          @icon={{ChevronDown}}
                          @size={{18}}
                          class="jn-size-4 rdp-chevron"
                        /></span>
                    </span>
                  {{else}}
                    <span>{{month.yearText}}</span>
                  {{/if}}
                  <span
                    role="status"
                    aria-live="polite"
                    data-test-jn-part="caption"
                    {{visuallyHidden}}
                  >{{month.caption}}</span>
                </div>
              {{else}}
                <span
                  class="rdp-caption_label"
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
              class="rdp-month_grid"
              data-test-jn-part="grid"
            >
              {{#unless @hideWeekdays}}
                <thead aria-hidden="true">
                  <tr class="rdp-weekdays">
                    {{#if @showWeekNumber}}
                      <th
                        aria-label={{this.weekNumberHeaderLabel}}
                        class="rdp-week_number_header"
                        scope="col"
                      >{{this.weekNumberHeader}}</th>
                    {{/if}}
                    {{#each this.state.weekdays key="key" as |weekday|}}
                      <th
                        aria-label={{weekday.label}}
                        class="rdp-weekday"
                        scope="col"
                        data-test-jn-part="weekday"
                      >{{weekday.name}}</th>
                    {{/each}}
                  </tr>
                </thead>
              {{/unless}}
              <tbody class="rdp-weeks">
                {{#each month.weeks key="key" as |week|}}
                  <tr class="rdp-week" data-test-jn-part="week">
                    {{#if @showWeekNumber}}
                      {{! Upstream's WeekNumber is a td with react-day-picker's scope="row",
                          which HTML allows only on a th (axe's scope-attr-valid); Joinery's
                          leaves the scope off, and keeps its role. }}
                      <td
                        aria-label={{week.numberLabel}}
                        class="rdp-week_number"
                        role="rowheader"
                        data-test-jn-part="week-number"
                      ><div class="jn-calendar-week-number">{{week.numberText}}</div></td>
                    {{/if}}
                    {{#each week.days key="key" as |day|}}
                      <td
                        class="group/day {{day.className}}"
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
                            class="jn-button group/button jn-button-variant-ghost jn-button-size-icon jn-calendar-day-button rdp-day rdp-day_button"
                            data-slot="button"
                            data-variant="ghost"
                            data-size="icon"
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
