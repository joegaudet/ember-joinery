import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Calendar } from '@ember-joinery/ember'

export default class CalendarRtl extends Component {
  @tracked date: Date | undefined = new Date()

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    {{!
      Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor). Upstream's
      passes its language picker's dir and react-day-picker's arSA (or he) locale; Joinery's
      takes its direction from the nearest dir, and its names from Intl in @locale, so this is
      its Arabic, which upstream's preview opens in.
    }}
    <Calendar
      @mode="single"
      @value={{this.date}}
      @onValueChange={{this.setDate}}
      class="rounded-lg border [--cell-size:--spacing(9)]"
      @captionLayout="dropdown"
      @locale="ar-SA"
    />
  </template>
}
