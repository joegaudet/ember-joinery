import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { ChevronDown } from 'lucide'
import type { ControlSignature } from '@ember-formwright/ember'
import { Button, Calendar, Icon, Popover } from '@ember-joinery/ember'
import type { CalendarValue, CaptionLayout, Matcher } from '@ember-joinery/primitives/calendar'

export interface DatePickerControlSignature {
  Args: ControlSignature<Date | null>['Args'] & {
    /** How the trigger writes the date. Default: Intl's long date in `@locale` (`November 10, 2026`). */
    formatDate?: (date: Date) => string
    /** The days that can't be picked, as Calendar's `@disabled`. */
    disabledDays?: Matcher | Matcher[]
    /** Calendar's `@captionLayout`: `dropdown` picks the month and year from lists. */
    captionLayout?: CaptionLayout
    /** The earliest month the calendar shows. */
    startMonth?: Date
    /** The latest month the calendar shows. */
    endMonth?: Date
  }
  /** The trigger, an outline Button, which the field's label names. */
  Element: HTMLButtonElement | HTMLAnchorElement
}

/**
 * Upstream's Date Picker as a Formwright control, `@control="date-picker"`: an outline Button
 * showing the date (or `@placeholder`, `Pick a date` by default), which opens a Popover with a
 * Calendar. Picking a day stores it, as a `Date` at local midnight, and closes the popover.
 */
export class DatePickerControl extends Component<DatePickerControlSignature> {
  @tracked open = false

  get date(): Date | undefined {
    return this.args.value instanceof Date ? this.args.value : undefined
  }

  get text(): string {
    const date = this.date
    if (!date) return ''
    if (this.args.formatDate) return this.args.formatDate(date)
    return new Intl.DateTimeFormat(this.args.locale, { dateStyle: 'long' }).format(date)
  }

  get placeholder(): string {
    return this.args.placeholder ?? 'Pick a date'
  }

  get disabled(): boolean {
    return Boolean(this.args.disabled || this.args.readonly)
  }

  setOpen = (open: boolean): void => {
    this.open = open
  }

  select = (value: CalendarValue): void => {
    this.args.onChange(value instanceof Date ? value : null)
    this.open = false
  }

  <template>
    <Popover @open={{this.open}} @onOpenChange={{this.setOpen}} as |p|>
      <Button
        @variant="outline"
        id={{@id}}
        class="jn-formwright-date-picker-trigger"
        disabled={{this.disabled}}
        aria-invalid={{if @invalid "true"}}
        aria-describedby={{@describedBy}}
        data-empty={{if this.date "false" "true"}}
        data-test-fw-control={{@type}}
        ...attributes
        {{p.trigger}}
      >
        {{#if this.date}}{{this.text}}{{else}}<span>{{this.placeholder}}</span>{{/if}}
        <Icon @icon={{ChevronDown}} />
      </Button>
      <p.Content class="jn-formwright-date-picker-content" @align="start">
        <Calendar
          @mode="single"
          @value={{this.date}}
          @onValueChange={{this.select}}
          @defaultMonth={{this.date}}
          @disabled={{@disabledDays}}
          @captionLayout={{@captionLayout}}
          @startMonth={{@startMonth}}
          @endMonth={{@endMonth}}
          @locale={{@locale}}
        />
      </p.Content>
    </Popover>
  </template>
}
