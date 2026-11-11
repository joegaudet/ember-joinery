import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Calendar } from '@ember-joinery/ember'

export default class CalendarDemo extends Component {
  @tracked date: Date | undefined = new Date()

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    <Calendar
      @mode="single"
      @value={{this.date}}
      @onValueChange={{this.setDate}}
      class="rounded-lg border"
      @captionLayout="dropdown"
    />
  </template>
}
