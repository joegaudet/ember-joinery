import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { PowerCalendar } from '@ember-joinery/power-calendar'

// Formwright's controls-date-picker-inline, as a calendar of its own: a weekday in November or
// December, the weekends off.
const WEEKEND = ['Sat', 'Sun']

export default class PowerCalendarDisabledDays extends Component {
  @tracked shipsOn: Date | undefined = new Date(2026, 10, 18)

  setShipsOn = (date: Date | undefined) => (this.shipsOn = date)

  <template>
    <PowerCalendar
      @name="ships-on"
      @label="Ships on"
      @value={{this.shipsOn}}
      @onValueChange={{this.setShipsOn}}
      @required={{true}}
      @minDate="2026-11-02"
      @maxDate="2026-12-18"
      @disabledDates={{WEEKEND}}
      @locale="en-US"
      class="rounded-lg border"
    />
  </template>
}
