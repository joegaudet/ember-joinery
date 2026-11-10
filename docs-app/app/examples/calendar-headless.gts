import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Calendar, type CalendarValue } from '@ember-joinery/primitives/calendar'

const isWeekend = (date: Date) => date.getDay() === 0 || date.getDay() === 6

/** Its own classes for each part, as react-day-picker's `classNames`: rdp-* are left off. */
const CLASSES = {
  root: 'relative w-fit rounded-lg border p-3',
  months: 'flex flex-col gap-3',
  nav: 'absolute inset-x-3 top-3 flex justify-between',
  button_previous: 'flex size-8 items-center justify-center rounded-md hover:bg-muted',
  button_next: 'flex size-8 items-center justify-center rounded-md hover:bg-muted',
  chevron: 'size-4 fill-current',
  month_caption: 'flex h-8 items-center justify-center',
  caption_label: 'text-sm font-medium',
  month_grid: 'border-collapse',
  weekday: 'size-8 text-xs font-normal text-muted-foreground',
  day: 'size-8 p-0 text-center text-sm',
  day_button:
    'size-8 rounded-md hover:bg-muted focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:outline-none disabled:opacity-40',
  selected: '[&>button]:bg-primary [&>button]:text-primary-foreground',
  today: 'font-semibold',
  outside: 'text-muted-foreground',
}

/** Up to five days off, weekdays only, on the headless calendar. */
export default class CalendarHeadless extends Component {
  @tracked days: Date[] = []

  setDays = (value: CalendarValue) => (this.days = (value as Date[] | undefined) ?? [])

  get summary(): string {
    const count = this.days.length
    return count === 1 ? '1 day off' : `${count} days off`
  }

  <template>
    <div class="grid justify-items-center gap-3">
      <Calendar
        @mode="multiple"
        @max={{5}}
        @value={{this.days}}
        @onValueChange={{this.setDays}}
        @disabled={{isWeekend}}
        @showOutsideDays={{true}}
        @classNames={{CLASSES}}
      />
      <p class="text-sm text-muted-foreground" aria-live="polite">{{this.summary}}</p>
    </div>
  </template>
}
