import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Calendar as CalendarIcon } from 'lucide'
import { Calendar, Field, FieldLabel, Icon, InputGroup, Popover } from '@ember-joinery/ember'

function formatDate(date: Date | undefined) {
  if (!date) {
    return ''
  }

  return date.toLocaleDateString('en-US', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  })
}

function isValidDate(date: Date | undefined) {
  if (!date) {
    return false
  }
  return !isNaN(date.getTime())
}

export default class DatePickerInput extends Component {
  @tracked open = false
  @tracked date: Date | undefined = new Date('2025-06-01')
  @tracked month: Date | undefined = this.date
  @tracked value = formatDate(this.date)

  setOpen = (open: boolean) => (this.open = open)

  setMonth = (month: Date) => (this.month = month)

  change = (value: string) => {
    const date = new Date(value)
    this.value = value
    if (isValidDate(date)) {
      this.date = date
      this.month = date
    }
  }

  keyDown = (event: KeyboardEvent) => {
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      this.open = true
    }
  }

  select = (date: Date | undefined) => {
    this.date = date
    this.value = formatDate(date)
    this.open = false
  }

  <template>
    <Field class="mx-auto w-48">
      <FieldLabel for="date-required">Subscription Date</FieldLabel>
      <InputGroup as |g|>
        <g.Input
          id="date-required"
          @value={{this.value}}
          placeholder="June 01, 2025"
          @onValueChange={{this.change}}
          {{on "keydown" this.keyDown}}
        />
        {{!
          Radix's Popover renders no element, so upstream's button is directly in the addon,
          whose rule for a button there (has-[>button]) pulls it 0.3rem toward the end. Joinery's
          Popover root sits between them (display: contents), so here the button sits that much
          further in.
        }}
        <g.Addon @align="inline-end">
          <Popover @open={{this.open}} @onOpenChange={{this.setOpen}} as |p|>
            <g.Button
              id="date-picker"
              @variant="ghost"
              @size="icon-xs"
              aria-label="Select date"
              {{p.trigger}}
            >
              <Icon @icon={{CalendarIcon}} />
              <span class="sr-only">Select date</span>
            </g.Button>
            <p.Content
              class="w-auto overflow-hidden p-0"
              @align="end"
              @alignOffset={{-8}}
              @sideOffset={{10}}
            >
              <Calendar
                @mode="single"
                @value={{this.date}}
                @month={{this.month}}
                @onMonthChange={{this.setMonth}}
                @onValueChange={{this.select}}
              />
            </p.Content>
          </Popover>
        </g.Addon>
      </InputGroup>
    </Field>
  </template>
}
