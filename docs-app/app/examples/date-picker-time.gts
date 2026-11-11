import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { ChevronDown } from 'lucide'
import {
  Button,
  Calendar,
  Field,
  FieldGroup,
  FieldLabel,
  Icon,
  Input,
  Popover,
} from '@ember-joinery/ember'

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

export default class DatePickerTime extends Component {
  @tracked open = false
  @tracked date: Date | undefined = undefined

  setOpen = (open: boolean) => (this.open = open)

  select = (date: Date | undefined) => {
    this.date = date
    this.open = false
  }

  <template>
    <FieldGroup class="mx-auto max-w-xs flex-row">
      <Field>
        <FieldLabel for="date-picker-optional">Date</FieldLabel>
        {{!
          Upstream's button says w-32, but its Field's *:w-full, which comes later in Tailwind's
          order, stretches it: Radix's Popover renders no element, so the button is directly in
          the Field. Joinery's Popover root sits between them (display: contents), and Joinery's
          rules sit in a layer under the example's classes, so the button says w-full itself.
        }}
        <Popover @open={{this.open}} @onOpenChange={{this.setOpen}} as |p|>
          <Button
            @variant="outline"
            id="date-picker-optional"
            class="w-full justify-between font-normal"
            {{p.trigger}}
          >
            {{#if this.date}}{{format this.date}}{{else}}Select date{{/if}}
            <Icon @icon={{ChevronDown}} />
          </Button>
          <p.Content class="w-auto overflow-hidden p-0" @align="start">
            <Calendar
              @mode="single"
              @value={{this.date}}
              @captionLayout="dropdown"
              @defaultMonth={{this.date}}
              @onValueChange={{this.select}}
            />
          </p.Content>
        </Popover>
      </Field>
      <Field class="w-32">
        <FieldLabel for="time-picker-optional">Time</FieldLabel>
        {{!
          Upstream's Input keeps its dark:bg-input/30 over this bg-background, since shadcn's
          dark variant weighs a class more. Joinery's rules sit in a layer under the example's
          classes, so the example says dark:bg-input/30 itself.
        }}
        <Input
          type="time"
          id="time-picker-optional"
          step="1"
          @defaultValue="10:30:00"
          class="appearance-none bg-background dark:bg-input/30 [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
        />
      </Field>
    </FieldGroup>
  </template>
}
