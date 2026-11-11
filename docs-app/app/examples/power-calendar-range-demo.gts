import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { PowerCalendarRange, type DateRange } from '@ember-joinery/power-calendar'

// Formwright's date-range control, as a calendar of its own: a stay, its first night to its
// last.
export default class PowerCalendarRangeDemo extends Component {
  @tracked stay: DateRange = { from: new Date(2026, 10, 12), to: new Date(2026, 10, 16) }

  setStay = (stay: DateRange) => (this.stay = stay)

  <template>
    <PowerCalendarRange
      @name="stay"
      @label="Stay"
      @value={{this.stay}}
      @onValueChange={{this.setStay}}
      @locale="en-US"
      class="rounded-lg border"
    />
  </template>
}
