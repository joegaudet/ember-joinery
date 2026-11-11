import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Button, Calendar, Field, FieldLabel, Popover } from '@ember-joinery/ember'

const LONG = new Intl.DateTimeFormat('en-US', { dateStyle: 'long' })
const ORDINAL = new Intl.PluralRules('en-US', { type: 'ordinal' })
const SUFFIXES: Partial<Record<Intl.LDMLPluralRule, string>> = { one: 'st', two: 'nd', few: 'rd' }

/**
 * Upstream's `format(date, "PPP")`, `November 10th, 2026`. That is date-fns'; Joinery has no
 * date library, so this is Intl's long date with the day's ordinal suffix.
 */
function format(date: Date): string {
  const suffix = SUFFIXES[ORDINAL.select(date.getDate())] ?? 'th'
  return LONG.formatToParts(date)
    .map(part => (part.type === 'day' ? `${part.value}${suffix}` : part.value))
    .join('')
}

export default class DatePickerSimple extends Component {
  @tracked date: Date | undefined

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    <Field class="mx-auto w-44">
      <FieldLabel for="date-picker-simple">Date</FieldLabel>
      <Popover as |p|>
        <Button
          @variant="outline"
          id="date-picker-simple"
          class="justify-start font-normal"
          {{p.trigger}}
        >
          {{#if this.date}}{{format this.date}}{{else}}<span>Pick a date</span>{{/if}}
        </Button>
        <p.Content class="w-auto p-0" @align="start">
          <Calendar
            @mode="single"
            @value={{this.date}}
            @onValueChange={{this.setDate}}
            @defaultMonth={{this.date}}
          />
        </p.Content>
      </Popover>
    </Field>
  </template>
}
