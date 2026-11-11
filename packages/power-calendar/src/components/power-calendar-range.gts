import type Owner from '@ember/owner'
import EmberPowerCalendarRange from 'ember-power-calendar/components/power-calendar-range'
import type { NormalizeRangeActionValue } from 'ember-power-calendar/utils'
import { toDate, type DateRange } from '../dates.ts'
import { CalendarBase } from '../-private/calendar.gts'
import { RangeDays } from '../-private/days.gts'
import { CalendarCaption, CalendarNav } from '../-private/nav.gts'
import { OwnedValue, type CalendarOptions } from '../-private/state.ts'

export interface PowerCalendarRangeSignature {
  Args: CalendarOptions & {
    /** The range chosen, `{ from, to }`; pass it (even `undefined`) to control it. */
    value?: DateRange | null
    /** The range chosen first, while you don't control it. */
    defaultValue?: DateRange | null
    /** Called as the range is chosen: `{ from }` after the first press, `{ from, to }` after the second. */
    onValueChange?: (range: DateRange) => void
    /** The shortest range, in days between its ends. Default 0: a range can be one day. */
    minRange?: number
    /** The longest range, in days between its ends. Default: no limit. */
    maxRange?: number
    /** Once both ends are chosen, a press moves the nearer end, rather than starting again. */
    proximitySelection?: boolean
  }
  /** ember-power-calendar's root, a `group` named by `@label`. */
  Element: HTMLElement
}

/**
 * A calendar to choose a range of days: shadcn's Calendar (`mode="range"`), on
 * ember-power-calendar's range calendar. The first press chooses one end, the second the other
 * (in either order); the ends are filled, and the days between them shaded, as one band. A
 * third press starts a new range, or with `@proximitySelection`, moves the nearer end.
 *
 *   <PowerCalendarRange @value={{this.stay}} @onValueChange={{this.setStay}} @minRange={{1}} />
 *
 * The value is `{ from, to }`, `Date`s at local midnight, as shadcn's `DateRange`. While a start
 * is chosen without an end, the days closer to it than `@minRange` or further than `@maxRange`
 * can't be pressed. Its keyboard is the single calendar's.
 */
export default class PowerCalendarRange extends CalendarBase<PowerCalendarRangeSignature> {
  selection: OwnedValue<DateRange | undefined>

  constructor(owner: Owner, args: PowerCalendarRangeSignature['Args']) {
    super(owner, args)
    this.selection = new OwnedValue<DateRange | undefined>({
      controlled: () => 'value' in this.args,
      value: () => this.args.value ?? undefined,
      initial: args.defaultValue ?? undefined,
      onChange: range => {
        if (range) this.args.onValueChange?.(range)
      },
    })
  }

  get defaultLabel(): string {
    return 'Choose date range'
  }

  /** The range as ember-power-calendar holds it. */
  get selected(): { start: Date | undefined; end: Date | undefined } {
    const range = this.selection.value
    return { start: toDate(range?.from), end: toDate(range?.to) }
  }

  get minRange(): number {
    return this.args.minRange ?? 0
  }

  onSelect = (value: NormalizeRangeActionValue): void => {
    this.selection.set({ from: toDate(value.date.start), to: toDate(value.date.end) })
  }

  <template>
    <EmberPowerCalendarRange
      @selected={{this.selected}}
      @center={{this.center.value}}
      @locale={{@locale}}
      @minRange={{this.minRange}}
      @maxRange={{@maxRange}}
      @proximitySelection={{@proximitySelection}}
      @onSelect={{if this.interactive this.onSelect}}
      @onCenterChange={{this.onCenterChange}}
      @daysComponent={{RangeDays}}
      class="jn-calendar jn-power-calendar group/calendar"
      data-slot="calendar"
      data-test-jn="power-calendar-range"
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
    </EmberPowerCalendarRange>
  </template>
}
