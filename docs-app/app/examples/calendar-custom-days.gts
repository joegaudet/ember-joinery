import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import {
  addDays,
  defaultCalendarLabels,
  type CalendarModifiers,
  type CalendarLocale,
  type DateRange,
} from '@ember-joinery/primitives/calendar'
import { Calendar, Card } from '@ember-joinery/ember'

const isWeekend = (date: Date) => date.getDay() === 0 || date.getDay() === 6
const price = (date: Date) => (isWeekend(date) ? '$120' : '$100')

export default class CalendarCustomDays extends Component {
  @tracked range: DateRange | undefined = {
    from: new Date(new Date().getFullYear(), 11, 8),
    to: addDays(new Date(new Date().getFullYear(), 11, 8), 10),
  }

  setRange = (range: DateRange | undefined) => (this.range = range)

  formatters = {
    formatMonthDropdown: (date: Date) => {
      return date.toLocaleString('default', { month: 'long' })
    },
  }

  // Not upstream's: a day's button shows its price, so its name starts with what it shows, the
  // number and the price, as WCAG 2.5.3 asks (upstream's names only the date).
  labels = {
    labelDayButton: (date: Date, modifiers: CalendarModifiers, locale: CalendarLocale) => {
      const label = defaultCalendarLabels.labelDayButton(date, modifiers, locale)
      return modifiers.outside ? label : `${date.getDate()} ${price(date)}, ${label}`
    },
  }

  <template>
    <Card class="mx-auto w-fit p-0" as |c|>
      <c.Content class="p-0">
        <Calendar
          @mode="range"
          @defaultMonth={{this.range.from}}
          @value={{this.range}}
          @onValueChange={{this.setRange}}
          @numberOfMonths={{1}}
          @captionLayout="dropdown"
          class="[--cell-size:--spacing(10)] md:[--cell-size:--spacing(12)]"
          @formatters={{this.formatters}}
          @labels={{this.labels}}
        >
          <:day as |day|>
            {{day.label}}
            {{#unless day.modifiers.outside}}
              <span>{{price day.date}}</span>
            {{/unless}}
          </:day>
        </Calendar>
      </c.Content>
    </Card>
  </template>
}
