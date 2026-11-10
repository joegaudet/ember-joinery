import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldLabel } from '@ember-joinery/ember'
import { DateRangePicker, type DateRange } from '@ember-joinery/power-calendar'

// shadcn's date-picker-range, on a DateRangePicker: three weeks from January 20th.
export default class PowerDateRangePickerDemo extends Component {
  @tracked range: DateRange | undefined = {
    from: new Date(2026, 0, 20),
    to: new Date(2026, 1, 9),
  }

  setRange = (range: DateRange | undefined) => (this.range = range)

  <template>
    <Field class="mx-auto w-60">
      <FieldLabel for="date-picker-range">Date Picker Range</FieldLabel>
      <DateRangePicker
        @name="range"
        @id="date-picker-range"
        @value={{this.range}}
        @onValueChange={{this.setRange}}
        @locale="en-US"
        class="justify-start px-2.5"
      />
    </Field>
  </template>
}
