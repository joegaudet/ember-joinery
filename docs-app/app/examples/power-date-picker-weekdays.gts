import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldDescription, FieldLabel } from '@ember-joinery/ember'
import { DatePicker } from '@ember-joinery/power-calendar'

// Formwright's controls-date-picker-inline, ported: a weekday in November or December, written
// in full.
const WEEKEND = ['Sat', 'Sun']
const FULL: Intl.DateTimeFormatOptions = { dateStyle: 'full' }

export default class PowerDatePickerWeekdays extends Component {
  @tracked shipsOn: Date | undefined = new Date(2026, 10, 18)

  setShipsOn = (date: Date | undefined) => (this.shipsOn = date)

  <template>
    <Field class="w-full max-w-xs">
      <FieldLabel for="ships-on">Ships on</FieldLabel>
      <DatePicker
        @name="ships-on"
        @id="ships-on"
        @value={{this.shipsOn}}
        @onValueChange={{this.setShipsOn}}
        @format={{FULL}}
        @minDate="2026-11-02"
        @maxDate="2026-12-18"
        @disabledDates={{WEEKEND}}
        @describedBy="ships-on-hint"
        @locale="en-US"
      />
      <FieldDescription id="ships-on-hint">A weekday in November or December</FieldDescription>
    </Field>
  </template>
}
