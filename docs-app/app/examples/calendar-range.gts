import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { addDays, type DateRange } from '@ember-joinery/primitives/calendar'
import { Calendar, Card } from '@ember-joinery/ember'

export default class CalendarRange extends Component {
  // Upstream's addDays is date-fns'; Joinery's calendar has its own, so no date library.
  @tracked dateRange: DateRange | undefined = {
    from: new Date(new Date().getFullYear(), 0, 12),
    to: addDays(new Date(new Date().getFullYear(), 0, 12), 30),
  }

  setDateRange = (range: DateRange | undefined) => (this.dateRange = range)

  isDisabled = (date: Date) => date > new Date() || date < new Date('1900-01-01')

  <template>
    <Card class="mx-auto w-fit p-0" as |c|>
      <c.Content class="p-0">
        <Calendar
          @mode="range"
          @defaultMonth={{this.dateRange.from}}
          @value={{this.dateRange}}
          @onValueChange={{this.setDateRange}}
          @numberOfMonths={{2}}
          @disabled={{this.isDisabled}}
        />
      </c.Content>
    </Card>
  </template>
}
