import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { PowerCalendarRange, formatDateRange, type DateRange } from '@ember-joinery/power-calendar'

// One to seven nights, from today on: once the first night is chosen, the days too close to it
// or too far from it can't be the last.
export default class PowerCalendarRangeLimits extends Component {
  @tracked stay: DateRange | undefined

  today = new Date()

  setStay = (stay: DateRange) => (this.stay = stay)

  get summary(): string {
    return formatDateRange(this.stay, { locale: 'en-US', format: { dateStyle: 'medium' } })
  }

  <template>
    <div class="flex flex-col items-center gap-3">
      <PowerCalendarRange
        @name="nights"
        @label="Nights"
        @value={{this.stay}}
        @onValueChange={{this.setStay}}
        @minDate={{this.today}}
        @minRange={{1}}
        @maxRange={{7}}
        @locale="en-US"
        class="rounded-lg border"
      />
      <p class="text-sm text-muted-foreground" aria-live="polite">
        {{if this.summary this.summary "One to seven nights"}}
      </p>
    </div>
  </template>
}
