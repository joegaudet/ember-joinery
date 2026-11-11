import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { ChevronDown } from 'lucide'
import { Button, Calendar, Icon, Popover } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  placeholder: 'اختر تاريخًا',
}

/**
 * Upstream's `format(date, "PPP", { locale: arSA })`, `نوفمبر 10, 2026`. That is date-fns';
 * Joinery has no date library, so this writes arSA's `PPP` (`MMMM do, y`, its ordinal the bare
 * number) from Intl's parts: the month's Arabic name in the Gregorian calendar, and Latin
 * digits, as date-fns' arSA and the calendar's `ar-SA` have them.
 */
const PARTS = new Intl.DateTimeFormat('ar-SA-u-ca-gregory-nu-latn', {
  day: 'numeric',
  month: 'long',
  year: 'numeric',
})
function format(date: Date): string {
  const parts = PARTS.formatToParts(date)
  const part = (type: Intl.DateTimeFormatPartTypes) =>
    parts.find(found => found.type === type)?.value ?? ''
  return `${part('month')} ${part('day')}, ${part('year')}`
}

export default class DatePickerRtl extends Component {
  @tracked date: Date | undefined

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    {{!
      Upstream passes its language picker's dir to the button, the content and the calendar,
      and react-day-picker's arSA (or he) locale to the calendar. Joinery's take the same dir,
      and the calendar its names from Intl in @locale.
    }}
    <Popover as |p|>
      <Button
        @variant="outline"
        data-empty={{if this.date "false" "true"}}
        class="w-[212px] justify-between text-left font-normal data-[empty=true]:text-muted-foreground"
        dir="rtl"
        {{p.trigger}}
      >
        {{#if this.date}}{{format this.date}}{{else}}<span>{{t.placeholder}}</span>{{/if}}
        <Icon @icon={{ChevronDown}} />
      </Button>
      <p.Content class="w-auto p-0" @align="start" dir="rtl">
        <Calendar
          @mode="single"
          @value={{this.date}}
          @onValueChange={{this.setDate}}
          @defaultMonth={{this.date}}
          @dir="rtl"
          @locale="ar-SA"
        />
      </p.Content>
    </Popover>
  </template>
}
