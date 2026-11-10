import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { PowerCalendarMultiple } from '@ember-joinery/power-calendar'

// shadcn's calendar-multiple, with a limit: up to three days.
export default class PowerCalendarMultipleDemo extends Component {
  @tracked days: Date[] = [new Date(2026, 2, 3), new Date(2026, 2, 10)]

  setDays = (days: Date[]) => (this.days = days)

  <template>
    <div class="flex flex-col items-center gap-3">
      <PowerCalendarMultiple
        @name="days"
        @label="Workshop days"
        @value={{this.days}}
        @onValueChange={{this.setDays}}
        @maxLength={{3}}
        @locale="en-US"
        class="rounded-lg border"
      />
      <p class="text-sm text-muted-foreground" aria-live="polite">
        {{this.days.length}}
        of 3 days chosen
      </p>
    </div>
  </template>
}
