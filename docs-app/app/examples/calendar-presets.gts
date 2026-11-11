import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { addDays } from '@ember-joinery/primitives/calendar'
import { Button, Calendar, Card } from '@ember-joinery/ember'

const PRESETS = [
  { label: 'Today', value: 0 },
  { label: 'Tomorrow', value: 1 },
  { label: 'In 3 days', value: 3 },
  { label: 'In a week', value: 7 },
  { label: 'In 2 weeks', value: 14 },
]

export default class CalendarWithPresets extends Component {
  @tracked date: Date | undefined = new Date(new Date().getFullYear(), 1, 12)
  @tracked currentMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1)

  setDate = (date: Date | undefined) => (this.date = date)

  setCurrentMonth = (month: Date) => (this.currentMonth = month)

  choose = (days: number) => {
    const newDate = addDays(new Date(), days)
    this.date = newDate
    this.currentMonth = new Date(newDate.getFullYear(), newDate.getMonth(), 1)
  }

  <template>
    <Card class="mx-auto w-fit max-w-[300px]" @size="sm" as |c|>
      <c.Content>
        <Calendar
          @mode="single"
          @value={{this.date}}
          @onValueChange={{this.setDate}}
          @month={{this.currentMonth}}
          @onMonthChange={{this.setCurrentMonth}}
          @fixedWeeks={{true}}
          class="p-0 [--cell-size:--spacing(9.5)]"
        />
      </c.Content>
      <c.Footer class="flex flex-wrap gap-2 border-t">
        {{#each PRESETS as |preset|}}
          <Button
            @variant="outline"
            @size="sm"
            class="flex-1"
            {{on "click" (fn this.choose preset.value)}}
          >
            {{preset.label}}
          </Button>
        {{/each}}
      </c.Footer>
    </Card>
  </template>
}
