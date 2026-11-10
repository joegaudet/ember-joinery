import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import { ChevronLeft, ChevronRight } from 'lucide'
import { buttonClasses, Icon } from '@ember-joinery/ember'
import { formatDate } from 'ember-power-calendar/utils'

/** What the nav and caption read from the calendar ember-power-calendar yields. */
export interface NavCalendar {
  uniqueId: string
  calendarUniqueId?: string
  center: Date
  locale: string
  actions: {
    moveCenter?: (step: number, unit: 'month' | 'year', calendar: never, event: Event) => unknown
  }
}

function monthIndex(date: Date): number {
  return date.getFullYear() * 12 + date.getMonth()
}

export interface CalendarNavSignature {
  Args: {
    calendar: NavCalendar
    minDate?: Date
    maxDate?: Date
    previousLabel: string
    nextLabel: string
  }
}

const NAV_BUTTON = `${buttonClasses({ variant: 'ghost' })} jn-power-calendar-nav-button`

/**
 * shadcn's nav: ghost Buttons for the previous and next month at the ends of the caption's row,
 * each a chevron, mirrored right to left. react-day-picker's is a `<nav>`; this one is a plain
 * `<div>`, so a page with several calendars doesn't repeat a landmark that navigates nowhere. A month before `@minDate` or after `@maxDate` can't be
 * shown, so its button is `aria-disabled` (focusable, and doing nothing).
 */
export class CalendarNav extends Component<CalendarNavSignature> {
  get previousDisabled(): boolean {
    const { calendar, minDate } = this.args
    if (!calendar.actions.moveCenter) return true
    return Boolean(minDate && monthIndex(calendar.center) <= monthIndex(minDate))
  }

  get nextDisabled(): boolean {
    const { calendar, maxDate } = this.args
    if (!calendar.actions.moveCenter) return true
    return Boolean(maxDate && monthIndex(calendar.center) >= monthIndex(maxDate))
  }

  previous = (event: Event): void => {
    if (this.previousDisabled) return
    const { calendar } = this.args
    void calendar.actions.moveCenter?.(-1, 'month', calendar as never, event)
  }

  next = (event: Event): void => {
    if (this.nextDisabled) return
    const { calendar } = this.args
    void calendar.actions.moveCenter?.(1, 'month', calendar as never, event)
  }

  <template>
    <div class="jn-power-calendar-nav" data-slot="calendar-nav">
      <button
        type="button"
        class={{NAV_BUTTON}}
        data-slot="button"
        data-variant="ghost"
        data-size="default"
        data-test-jn-part="previous"
        aria-label={{@previousLabel}}
        aria-disabled={{if this.previousDisabled "true"}}
        {{on "click" this.previous}}
      ><Icon @icon={{ChevronLeft}} class="jn-rtl-flip jn-size-4" /></button>
      <button
        type="button"
        class={{NAV_BUTTON}}
        data-slot="button"
        data-variant="ghost"
        data-size="default"
        data-test-jn-part="next"
        aria-label={{@nextLabel}}
        aria-disabled={{if this.nextDisabled "true"}}
        {{on "click" this.next}}
      ><Icon @icon={{ChevronRight}} class="jn-rtl-flip jn-size-4" /></button>
    </div>
  </template>
}

export interface CalendarCaptionSignature {
  Args: { calendar: NavCalendar }
}

/** The month shown, as the grid's name: "March 2026", in the calendar's locale. */
export class CalendarCaption extends Component<CalendarCaptionSignature> {
  get id(): string {
    const { calendar } = this.args
    return `${calendar.calendarUniqueId ?? calendar.uniqueId}-caption`
  }

  get text(): string {
    const { calendar } = this.args
    return formatDate(calendar.center, 'MMMM YYYY', calendar.locale)
  }

  <template>
    <div class="jn-power-calendar-month-caption" data-slot="calendar-month-caption">
      <span
        id={{this.id}}
        class="jn-power-calendar-caption-label"
        aria-live="polite"
        data-test-jn-part="caption"
      >{{this.text}}</span>
    </div>
  </template>
}
