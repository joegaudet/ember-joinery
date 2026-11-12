import type Owner from '@ember/owner'
import EmberPowerCalendar from 'ember-power-calendar/components/power-calendar'
import type { PowerCalendarDay } from 'ember-power-calendar/utils'
import { isSameDay, toDate } from '../dates.ts'
import { CalendarBase } from '../-private/calendar.gts'
import { SingleDays } from '../-private/days.gts'
import { CalendarCaption, CalendarNav } from '../-private/nav.gts'
import { OwnedValue, type CalendarOptions } from '../-private/state.ts'
import { translate } from '@ember-joinery/primitives/i18n'
import { messages } from '../messages.ts'

export interface PowerCalendarSignature {
  Args: CalendarOptions & {
    /** The day chosen; pass it (even `undefined`) to control it. */
    value?: Date | null
    /** The day chosen first, while you don't control it. */
    defaultValue?: Date | null
    /** Called with the day chosen, or `undefined` when the chosen day is pressed again. */
    onValueChange?: (date: Date | undefined) => void
    /** Pressing the chosen day keeps it, rather than clearing it. Default `false`. */
    required?: boolean
  }
  /** ember-power-calendar's root, a `group` named by `@label`. */
  Element: HTMLElement
}

/**
 * A calendar to choose one day: shadcn's Calendar (`mode="single"`), on ember-power-calendar.
 * The month's caption sits between ghost buttons for the previous and next month, over a grid
 * of the month's days, a ghost Button each; today is shaded and the chosen day is filled.
 *
 *   <PowerCalendar @value={{this.date}} @onValueChange={{this.setDate}} class="rounded-lg border" />
 *
 * The value is a `Date` (at local midnight), controlled or not. Pressing the chosen day again
 * clears it, as upstream's does, unless it is `@required`. The grid is WAI-ARIA's: the arrow
 * keys move by a day or a week (flipped right to left), Home and End to the week's ends, Page
 * Up and Page Down by a month (with Shift, a year), and Enter or Space chooses the day.
 */
export default class PowerCalendar extends CalendarBase<PowerCalendarSignature> {
  selection: OwnedValue<Date | undefined>

  constructor(owner: Owner, args: PowerCalendarSignature['Args']) {
    super(owner, args)
    this.selection = new OwnedValue<Date | undefined>({
      controlled: () => 'value' in this.args,
      value: () => toDate(this.args.value),
      initial: toDate(args.defaultValue),
      onChange: date => this.args.onValueChange?.(date),
    })
  }

  get defaultLabel(): string {
    return translate(this, messages.chooseDate)
  }

  get selected(): Date | undefined {
    return this.selection.value
  }

  onSelect = (day: PowerCalendarDay): void => {
    const date = toDate(day.date)
    if (!this.args.required && isSameDay(date, this.selected)) this.selection.set(undefined)
    else this.selection.set(date)
  }

  <template>
    <EmberPowerCalendar
      @selected={{this.selected}}
      @center={{this.center.value}}
      @locale={{this.locale}}
      @onSelect={{if this.interactive this.onSelect}}
      @onCenterChange={{this.onCenterChange}}
      @daysComponent={{SingleDays}}
      class="jn-calendar jn-power-calendar group/calendar"
      data-slot="calendar"
      data-test-jn="power-calendar"
      data-test-jn-name={{@name}}
      data-disabled={{if @disabled "true"}}
      aria-label={{this.label}}
      ...attributes
      as |calendar|
    >
      <div class="jn-power-calendar-months" data-slot="calendar-months">
        <CalendarNav
          @calendar={{calendar}}
          @minDate={{this.minDate}}
          @maxDate={{this.maxDate}}
          @previousLabel={{this.previousMonthLabel}}
          @nextLabel={{this.nextMonthLabel}}
        />
        <div class="jn-power-calendar-month" data-slot="calendar-month">
          <CalendarCaption @calendar={{calendar}} />
          <calendar.Days
            @minDate={{this.minDate}}
            @maxDate={{this.maxDate}}
            @disabledDates={{this.disabledDates}}
            @startOfWeek={{this.startOfWeek}}
            @showDaysAround={{this.showDaysAround}}
            @weekdayFormat={{this.weekdayFormat}}
          />
        </div>
      </div>
    </EmberPowerCalendar>
  </template>
}
