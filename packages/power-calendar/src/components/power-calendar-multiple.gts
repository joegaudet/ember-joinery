import type Owner from '@ember/owner'
import EmberPowerCalendarMultiple from 'ember-power-calendar/components/power-calendar-multiple'
import type { NormalizeMultipleActionValue } from 'ember-power-calendar/utils'
import { toDate } from '../dates.ts'
import { CalendarBase } from '../-private/calendar.gts'
import { MultipleDays } from '../-private/days.gts'
import { CalendarCaption, CalendarNav } from '../-private/nav.gts'
import { OwnedValue, type CalendarOptions } from '../-private/state.ts'

export interface PowerCalendarMultipleSignature {
  Args: CalendarOptions & {
    /** The days chosen, in the order they were; pass it (even `undefined`) to control it. */
    value?: readonly Date[] | null
    /** The days chosen first, while you don't control it. */
    defaultValue?: readonly Date[] | null
    /** Called with the days chosen whenever a press adds or removes one. */
    onValueChange?: (dates: Date[]) => void
    /** The most days that can be chosen; then only those can be pressed. Default: no limit. */
    maxLength?: number
  }
  /** ember-power-calendar's root, a `group` named by `@label`. */
  Element: HTMLElement
}

/**
 * A calendar to choose several days: shadcn's Calendar (`mode="multiple"`), on
 * ember-power-calendar's multiple calendar. Each press adds a day, or removes one already
 * chosen; the chosen days are filled.
 *
 *   <PowerCalendarMultiple @value={{this.days}} @onValueChange={{this.setDays}} @maxLength={{3}} />
 *
 * The value is an array of `Date`s at local midnight. With `@maxLength` days chosen, only those
 * can be pressed, until one is removed. Its keyboard is the single calendar's.
 */
export default class PowerCalendarMultiple extends CalendarBase<PowerCalendarMultipleSignature> {
  selection: OwnedValue<Date[]>

  constructor(owner: Owner, args: PowerCalendarMultipleSignature['Args']) {
    super(owner, args)
    this.selection = new OwnedValue<Date[]>({
      controlled: () => 'value' in this.args,
      value: () => dates(this.args.value),
      initial: dates(args.defaultValue),
      onChange: days => this.args.onValueChange?.(days),
    })
  }

  get defaultLabel(): string {
    return 'Choose dates'
  }

  get selected(): Date[] {
    return this.selection.value
  }

  onSelect = (value: NormalizeMultipleActionValue): void => {
    this.selection.set(dates(value.date))
  }

  <template>
    <EmberPowerCalendarMultiple
      @selected={{this.selected}}
      @center={{this.center.value}}
      @locale={{@locale}}
      @onSelect={{if this.interactive this.onSelect}}
      @onCenterChange={{this.onCenterChange}}
      @daysComponent={{MultipleDays}}
      class="jn-calendar jn-power-calendar group/calendar"
      data-slot="calendar"
      data-test-jn="power-calendar-multiple"
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
            @maxLength={{@maxLength}}
          />
        </div>
      </div>
    </EmberPowerCalendarMultiple>
  </template>
}

function dates(value: readonly unknown[] | null | undefined): Date[] {
  return (value ?? []).map(toDate).filter((date): date is Date => Boolean(date))
}
