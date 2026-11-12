import type Owner from '@ember/owner'
import { Calendar, ChevronDown } from 'lucide'
import type { IconNode } from '@ember-joinery/ember'
import { formatDate, parseDate, toDate } from '../dates.ts'
import { PickerBase, PickerFrame, type PickerOptions } from '../-private/picker.gts'
import { OwnedValue } from '../-private/state.ts'
import PowerCalendar from './power-calendar.gts'
import { translate } from '@ember-joinery/primitives/i18n'
import { messages } from '../messages.ts'

export interface DatePickerSignature {
  Args: PickerOptions & {
    /** The day chosen; pass it (even `undefined`) to control it. */
    value?: Date | null
    /** The day chosen first, while you don't control it. */
    defaultValue?: Date | null
    /** Called with the day chosen, typed, or cleared (`undefined`, from an emptied input). */
    onValueChange?: (date: Date | undefined) => void
  }
  /** The trigger `<button>`, or with `@trigger="input"`, the Input Group around the input. */
  Element: HTMLElement
}

/**
 * A date picker: shadcn's Date Picker, a Popover holding a `PowerCalendar`, opened from an
 * outlined Button that shows the date (as upstream's date-picker-demo), or from an input it can
 * be typed into, with a calendar button at its end (date-picker-input).
 *
 *   <DatePicker @value={{this.date}} @onValueChange={{this.setDate}} />
 *   <DatePicker @trigger="input" @id="due" @value={{this.due}} @onValueChange={{this.setDue}} />
 *
 * Choosing a day closes the calendar and focuses the trigger again (the input, for an input).
 * The value is a `Date` at local midnight, controlled or not; the calendar opens on its month,
 * with focus on it (else on today). Typed text that names a day (with its year) becomes the
 * value, and ArrowDown in the input opens the calendar.
 */
export default class DatePicker extends PickerBase<DatePickerSignature> {
  selection: OwnedValue<Date | undefined>

  constructor(owner: Owner, args: DatePickerSignature['Args']) {
    super(owner, args)
    this.selection = new OwnedValue<Date | undefined>({
      controlled: () => 'value' in this.args,
      value: () => toDate(this.args.value),
      initial: toDate(args.defaultValue),
      onChange: date => this.args.onValueChange?.(date),
    })
  }

  get component(): 'date-picker' {
    return 'date-picker'
  }

  get value(): Date | undefined {
    return this.selection.value
  }

  get text(): string {
    return formatDate(this.value, { locale: this.locale, format: this.args.format })
  }

  get valueText(): string {
    return this.text
  }

  get isEmpty(): boolean {
    return !this.value
  }

  get defaultPlaceholder(): string {
    return translate(this, messages.placeholder)
  }

  get defaultIcon(): IconNode {
    return this.inputMode ? Calendar : ChevronDown
  }

  get defaultIconPosition(): 'inline-start' | 'inline-end' {
    return 'inline-end'
  }

  get defaultTriggerLabel(): string {
    return translate(this, messages.selectDate)
  }

  readTyped(text: string): boolean {
    const date = parseDate(text)
    if (!date) return false
    this.selection.set(date)
    return true
  }

  clear(): void {
    if (this.value) this.selection.set(undefined)
  }

  reset(): void {
    // A single day has nothing held while the calendar is open.
  }

  choose = (date: Date | undefined): void => {
    if (date) this.selection.set(date)
    this.close()
  }

  <template>
    <PickerFrame @picker={{this}} ...attributes>
      <PowerCalendar
        @value={{this.value}}
        @onValueChange={{this.choose}}
        @required={{true}}
        @center={{this.center}}
        @onCenterChange={{this.setCenter}}
        @locale={{this.locale}}
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
