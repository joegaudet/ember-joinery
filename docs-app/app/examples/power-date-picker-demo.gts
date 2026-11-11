import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldDescription, FieldGroup, FieldLabel } from '@ember-joinery/ember'
import { DatePicker, DateRangePicker, type DateRange } from '@ember-joinery/power-calendar'

// Formwright's controls-date-picker, ported: a booking's check-in day and its stay, a Date and
// a { from, to } range.
export default class PowerDatePickerDemo extends Component {
  @tracked checkIn: Date | undefined = new Date(2026, 10, 12)
  @tracked stay: DateRange | undefined = {
    from: new Date(2026, 10, 12),
    to: new Date(2026, 10, 16),
  }

  setCheckIn = (date: Date | undefined) => (this.checkIn = date)
  setStay = (range: DateRange | undefined) => (this.stay = range)

  <template>
    <FieldGroup class="w-full max-w-xs">
      <Field>
        <FieldLabel for="check-in">Check-in</FieldLabel>
        <DatePicker
          @name="check-in"
          @id="check-in"
          @value={{this.checkIn}}
          @onValueChange={{this.setCheckIn}}
          @placeholder="Pick a day"
          @locale="en-US"
        />
      </Field>
      <Field>
        <FieldLabel for="stay">Stay</FieldLabel>
        <DateRangePicker
          @name="stay"
          @id="stay"
          @value={{this.stay}}
          @onValueChange={{this.setStay}}
          @placeholder="Check-in – check-out"
          @describedBy="stay-hint"
          @locale="en-US"
        />
        <FieldDescription id="stay-hint">Click the first night, then the last</FieldDescription>
      </Field>
    </FieldGroup>
  </template>
}
