import Component from '@glimmer/component'
import type Owner from '@ember/owner'
import { ensureDateLibrary } from '../date-library.ts'
import { toDate } from '../dates.ts'
import {
  OwnedValue,
  normalizeDisabledDates,
  startOfWeekArg,
  type CalendarOptions,
} from './state.ts'
import { translate, translator } from '@ember-joinery/primitives/i18n'
import { messages } from '../messages.ts'

/**
 * What the three calendars share: the month shown (controlled with `@center` or their own),
 * `@minDate`, `@maxDate` and `@disabledDates` read the way ember-power-calendar wants them, and
 * the built-in strings.
 */
export abstract class CalendarBase<S extends { Args: CalendarOptions }> extends Component<S> {
  center: OwnedValue<Date | undefined>

  constructor(owner: Owner, args: S['Args']) {
    super(owner, args)
    ensureDateLibrary()
    this.center = new OwnedValue<Date | undefined>({
      controlled: () => 'center' in this.args,
      value: () => toDate(this.args.center),
      initial: toDate(args.defaultCenter),
      onChange: center => {
        if (center) this.args.onCenterChange?.(center)
      },
    })
  }

  abstract get defaultLabel(): string

  get label(): string {
    return this.args.label ?? this.defaultLabel
  }

  /** `@locale`, else the app's translator's. */
  get locale(): string | undefined {
    return this.args.locale ?? translator(this)?.locale
  }

  get previousMonthLabel(): string {
    return this.args.previousMonthLabel ?? translate(this, messages.previousMonth)
  }

  get nextMonthLabel(): string {
    return this.args.nextMonthLabel ?? translate(this, messages.nextMonth)
  }

  get minDate(): Date | undefined {
    return toDate(this.args.minDate)
  }

  get maxDate(): Date | undefined {
    return toDate(this.args.maxDate)
  }

  get disabledDates(): Array<Date | string> | undefined {
    return normalizeDisabledDates(this.args.disabledDates)
  }

  get startOfWeek(): string | undefined {
    return startOfWeekArg(this.args.startOfWeek)
  }

  get showDaysAround(): boolean {
    return this.args.showDaysAround ?? true
  }

  get weekdayFormat(): 'min' | 'short' | 'long' {
    return this.args.weekdayFormat ?? 'short'
  }

  get interactive(): boolean {
    return !this.args.disabled
  }

  /** ember-power-calendar's `@onCenterChange`: keeps the month it moved to. */
  onCenterChange = (value: { date: Date | undefined }): void => {
    const date = toDate(value.date)
    if (date) this.center.set(date)
  }
}
