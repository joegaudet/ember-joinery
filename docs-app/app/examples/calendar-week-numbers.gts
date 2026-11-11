import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Calendar, Card } from '@ember-joinery/ember'

export default class CalendarWeekNumbers extends Component {
  @tracked date: Date | undefined = new Date(new Date().getFullYear(), 1, 3)

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    <Card class="mx-auto w-fit p-0" as |c|>
      <c.Content class="p-0">
        <Calendar
          @mode="single"
          @defaultMonth={{this.date}}
          @value={{this.date}}
          @onValueChange={{this.setDate}}
          @showWeekNumber={{true}}
        />
      </c.Content>
    </Card>
  </template>
}
