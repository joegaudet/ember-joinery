import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { PowerCalendar } from '@ember-joinery/power-calendar'

// shadcn's calendar-rtl, in Arabic, the language its preview opens in. The guide shows it with
// dir="rtl" on the preview; the calendar takes its direction from there.
const t = {
  label: 'اختر تاريخًا',
  previous: 'الشهر السابق',
  next: 'الشهر التالي',
}

export default class PowerCalendarRtl extends Component {
  @tracked date: Date | undefined = new Date(2026, 2, 4)

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    <PowerCalendar
      @name="rtl"
      @value={{this.date}}
      @onValueChange={{this.setDate}}
      @locale="ar"
      @label={{t.label}}
      @previousMonthLabel={{t.previous}}
      @nextMonthLabel={{t.next}}
      class="rounded-lg border"
    />
  </template>
}
