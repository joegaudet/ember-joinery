import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Calendar as CalendarIcon } from 'lucide'
import { addDays, type DateRange } from '@ember-joinery/primitives/calendar'
import { Button, Calendar, Field, FieldLabel, Icon, Popover } from '@ember-joinery/ember'

const SHORT = new Intl.DateTimeFormat('en-US', { month: 'short', day: '2-digit', year: 'numeric' })

/** Upstream's `format(date, "LLL dd, y")`, `Jan 20, 2026`, from Intl: no date library. */
const format = (date: Date) => SHORT.format(date)

export default class DatePickerWithRange extends Component {
  // Upstream's addDays is date-fns'; Joinery's calendar has its own, so no date library.
  @tracked date: DateRange | undefined = {
    from: new Date(new Date().getFullYear(), 0, 20),
    to: addDays(new Date(new Date().getFullYear(), 0, 20), 20),
  }

  setDate = (date: DateRange | undefined) => (this.date = date)

  <template>
    <Field class="mx-auto w-60">
      <FieldLabel for="date-picker-range">Date Picker Range</FieldLabel>
      <Popover as |p|>
        <Button
          @variant="outline"
          id="date-picker-range"
          class="justify-start px-2.5 font-normal"
          {{p.trigger}}
        >
          <Icon @icon={{CalendarIcon}} />
          {{#if this.date.from}}
            {{#if this.date.to}}
              {{format this.date.from}}
              -
              {{format this.date.to}}
            {{else}}
              {{format this.date.from}}
            {{/if}}
          {{else}}
            <span>Pick a date</span>
          {{/if}}
        </Button>
        <p.Content class="w-auto p-0" @align="start">
          <Calendar
            @mode="range"
            @defaultMonth={{this.date.from}}
            @value={{this.date}}
            @onValueChange={{this.setDate}}
            @numberOfMonths={{2}}
          />
        </p.Content>
      </Popover>
    </Field>
  </template>
}
