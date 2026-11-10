import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Calendar } from '@ember-joinery/ember'

export default class CalendarHijri extends Component {
  @tracked date: Date | undefined = new Date(2025, 5, 12)

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    {{!
      Upstream's builds a calendar of its own on react-day-picker/persian (Jalali dates, the
      fa-IR locale, Persian digits, right to left), with its own classes, and sets the
      Vazirmatn font. Joinery's Calendar takes the Persian calendar from Intl: @calendar,
      @locale and @numerals, and @dir. The classes are the ones that example's calendar sets
      differently from the Calendar's (p-3, a cell size of 8). Vazirmatn isn't loaded, as in
      the parity app's stand-in for next/font.
    }}
    <div>
      <Calendar
        @mode="single"
        @calendar="persian"
        @locale="fa-IR"
        @numerals="arabext"
        @dir="rtl"
        @defaultMonth={{this.date}}
        @value={{this.date}}
        @onValueChange={{this.setDate}}
        class="rounded-lg border p-3 [--cell-size:--spacing(8)]"
      />
    </div>
  </template>
}
