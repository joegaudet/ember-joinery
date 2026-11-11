import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { PowerCalendar } from '@ember-joinery/power-calendar'

// shadcn's calendar-demo, on ember-power-calendar: today, chosen, in a bordered box.
export default class PowerCalendarDemo extends Component {
  @tracked date: Date | undefined = new Date()

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    <PowerCalendar
      @name="demo"
      @value={{this.date}}
      @onValueChange={{this.setDate}}
      class="rounded-lg border"
    />
  </template>
}
