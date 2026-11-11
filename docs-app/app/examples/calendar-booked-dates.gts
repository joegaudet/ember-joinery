import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { Calendar, Card } from '@ember-joinery/ember'

export default class CalendarBookedDates extends Component {
  @tracked date: Date | undefined = new Date(new Date().getFullYear(), 1, 3)

  // Upstream imports react-day-picker's `es` locale here and doesn't use it.
  bookedDates = Array.from({ length: 15 }, (_, i) => new Date(new Date().getFullYear(), 1, 12 + i))

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    <Card class="mx-auto w-fit p-0" as |c|>
      <c.Content class="p-0">
        <Calendar
          @mode="single"
          @defaultMonth={{this.date}}
          @value={{this.date}}
          @onValueChange={{this.setDate}}
          @disabled={{this.bookedDates}}
          @modifiers={{hash booked=this.bookedDates}}
          @modifiersClassNames={{hash booked="[&>button]:line-through opacity-100"}}
        />
      </c.Content>
    </Card>
  </template>
}
