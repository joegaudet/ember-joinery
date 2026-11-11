import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldLabel } from '@ember-joinery/ember'
import { DatePicker } from '@ember-joinery/power-calendar'

// shadcn's date-picker-input, on a DatePicker with an input: type the date, or press the
// calendar button (or ArrowDown in the input) to choose it.
const FORMAT: Intl.DateTimeFormatOptions = { day: '2-digit', month: 'long', year: 'numeric' }

export default class PowerDatePickerInput extends Component {
  @tracked date: Date | undefined = new Date(2025, 5, 1)

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    <Field class="mx-auto w-48">
      <FieldLabel for="date-required">Subscription Date</FieldLabel>
      <DatePicker
        @name="subscription"
        @trigger="input"
        @id="date-required"
        @value={{this.date}}
        @onValueChange={{this.setDate}}
        @format={{FORMAT}}
        @placeholder="June 01, 2025"
        @locale="en-US"
      />
    </Field>
  </template>
}
