import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldDescription, FieldLabel } from '@ember-joinery/ember'
import { DateRangePicker, type DateRange } from '@ember-joinery/power-calendar'

// A DateRangePicker with an input: type both dates, a dash between them, or choose them in the
// calendar.
export default class PowerDateRangePickerInput extends Component {
  @tracked trip: DateRange | undefined

  setTrip = (range: DateRange | undefined) => (this.trip = range)

  <template>
    <Field class="mx-auto w-72">
      <FieldLabel for="trip">Trip</FieldLabel>
      <DateRangePicker
        @name="trip"
        @trigger="input"
        @id="trip"
        @value={{this.trip}}
        @onValueChange={{this.setTrip}}
        @placeholder="Mar 4, 2026 – Mar 9, 2026"
        @describedBy="trip-hint"
        @locale="en-US"
      />
      <FieldDescription id="trip-hint">The first day, a dash, then the last</FieldDescription>
    </Field>
  </template>
}
