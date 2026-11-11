import { tracked } from '@glimmer/tracking'
import type Owner from '@ember/owner'
import { Calendar } from 'lucide'
import type { IconNode } from '@ember-joinery/ember'
import {
  formatDate,
  formatDateRange,
  parseDate,
  toDate,
  type DateRange,
  type FormatOptions,
} from '../dates.ts'
import { PickerBase, PickerFrame, type PickerOptions } from '../-private/picker.gts'
import { OwnedValue } from '../-private/state.ts'
import PowerCalendarRange from './power-calendar-range.gts'

export interface DateRangePickerSignature {
  Args: PickerOptions & {
    /** The range chosen, `{ from, to }`; pass it (even `undefined`) to control it. */
    value?: DateRange | null
    /** The range chosen first, while you don't control it. */
    defaultValue?: DateRange | null
    /** Called with the range once both ends are chosen (or typed), or `undefined` when cleared. */
    onValueChange?: (range: DateRange | undefined) => void
    /** The shortest range, in days between its ends. Default 0: a range can be one day. */
    minRange?: number
    /** The longest range, in days between its ends. Default: no limit. */
    maxRange?: number
  }
  /** The trigger `<button>`, or with `@trigger="input"`, the Input Group around the input. */
  Element: HTMLElement
}

/** What sits between the two dates in the input: an en dash, spaced. */
const SEPARATOR = ' – '
/** What splits typed text into its two dates: a dash, a hyphen or "to", spaced. */
const SPLIT = /\s+(?:–|—|-|to)\s+/i

/**
 * A date range picker: shadcn's Range Picker, a Popover holding a `PowerCalendarRange`, opened
 * from an outlined Button with a calendar icon (as upstream's date-picker-range), or from an
 * input both dates can be typed into.
 *
 *   <DateRangePicker @value={{this.stay}} @onValueChange={{this.setStay}} />
 *
 * The first day pressed starts the range and the second ends it (in either order); only then
 * does the value change and the calendar close, so closing it in between keeps the range there
 * was. The value is `{ from, to }`, `Date`s at local midnight, as shadcn's `DateRange`.
 */
export default class DateRangePicker extends PickerBase<DateRangePickerSignature> {
  selection: OwnedValue<DateRange | undefined>
  /** The start chosen before the end, held until the range is whole. */
  @tracked pending: DateRange | undefined

  constructor(owner: Owner, args: DateRangePickerSignature['Args']) {
    super(owner, args)
    this.selection = new OwnedValue<DateRange | undefined>({
      controlled: () => 'value' in this.args,
      value: () => this.args.value ?? undefined,
      initial: args.defaultValue ?? undefined,
      onChange: range => this.args.onValueChange?.(range),
    })
  }

  get component(): 'date-range-picker' {
    return 'date-range-picker'
  }

  get value(): DateRange | undefined {
    return this.selection.value
  }

  /** What the calendar shows: the range being chosen, else the value. */
  get shown(): DateRange | undefined {
    return this.pending ?? this.value
  }

  get formatOptions(): FormatOptions {
    return { locale: this.args.locale, format: this.args.format ?? { dateStyle: 'medium' } }
  }

  get text(): string {
    return formatDateRange(this.value, this.formatOptions)
  }

  /** Both dates in full, so the input's text reads back as the range. */
  get valueText(): string {
    const from = toDate(this.value?.from)
    const to = toDate(this.value?.to)
    if (!from) return ''
    const options = this.formatOptions
    return to
      ? `${formatDate(from, options)}${SEPARATOR}${formatDate(to, options)}`
      : formatDate(from, options)
  }

  get isEmpty(): boolean {
    return !toDate(this.value?.from)
  }

  get defaultPlaceholder(): string {
    return 'Pick a date'
  }

  get defaultIcon(): IconNode {
    return Calendar
  }

  get defaultIconPosition(): 'inline-start' | 'inline-end' {
    return 'inline-start'
  }

  get defaultTriggerLabel(): string {
    return 'Select dates'
  }

  readTyped(text: string): boolean {
    const [first = '', second, ...rest] = text.split(SPLIT)
    if (rest.length || second === undefined) return false
    const from = parseDate(first)
    const to = parseDate(second)
    if (!from || !to) return false
    this.selection.set(+from <= +to ? { from, to } : { from: to, to: from })
    return true
  }

  clear(): void {
    if (this.value) this.selection.set(undefined)
  }

  reset(): void {
    this.pending = undefined
  }

  choose = (range: DateRange): void => {
    if (range.from && range.to) {
      this.pending = undefined
      this.selection.set({ from: range.from, to: range.to })
      this.close()
    } else {
      this.pending = range
    }
  }

  <template>
    <PickerFrame @picker={{this}} ...attributes>
      <PowerCalendarRange
        @value={{this.shown}}
        @onValueChange={{this.choose}}
        @center={{this.center}}
        @onCenterChange={{this.setCenter}}
        @minRange={{@minRange}}
        @maxRange={{@maxRange}}
        @locale={{@locale}}
        @minDate={{@minDate}}
        @maxDate={{@maxDate}}
        @disabledDates={{@disabledDates}}
        @startOfWeek={{@startOfWeek}}
        @showDaysAround={{@showDaysAround}}
        @weekdayFormat={{@weekdayFormat}}
        @label={{@label}}
        @previousMonthLabel={{@previousMonthLabel}}
        @nextMonthLabel={{@nextMonthLabel}}
      />
    </PickerFrame>
  </template>
}
