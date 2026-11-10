import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { DatePicker } from '@ember-joinery/power-calendar'

// shadcn's date-picker-rtl, in Arabic, the language its preview opens in. The guide shows it
// with dir="rtl" on the preview; the trigger and the calendar take their direction from there.
const t = {
  placeholder: 'اختر تاريخًا',
  label: 'اختر تاريخًا',
  previous: 'الشهر السابق',
  next: 'الشهر التالي',
}

export default class PowerDatePickerRtl extends Component {
  @tracked date: Date | undefined

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    <DatePicker
      @name="rtl"
      @value={{this.date}}
      @onValueChange={{this.setDate}}
      @locale="ar"
      @placeholder={{t.placeholder}}
      @label={{t.label}}
      @previousMonthLabel={{t.previous}}
      @nextMonthLabel={{t.next}}
      class="w-[212px]"
    />
  </template>
}
