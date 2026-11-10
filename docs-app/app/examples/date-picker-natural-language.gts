import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { parseDate } from 'chrono-node'
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

export default class DatePickerNaturalLanguage extends Component {
  @tracked open = false
  @tracked value = 'In 2 days'
  @tracked date: Date | undefined = parseDate(this.value) || undefined

  setOpen = (open: boolean) => (this.open = open)

  change = (value: string) => {
    this.value = value
    const date = parseDate(value)
    if (date) {
      this.date = date
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
    {{!
      Upstream parses what you type with chrono-node, a natural-language date parser; so does
      this example. It is the example's own dependency: Joinery's components need no date
      library.
    }}
    <Field class="mx-auto max-w-xs">
      <FieldLabel for="date-optional">Schedule Date</FieldLabel>
      <InputGroup as |g|>
        <g.Input
          id="date-optional"
          @value={{this.value}}
          placeholder="Tomorrow or next week"
          @onValueChange={{this.change}}
          {{on "keydown" this.keyDown}}
        />
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
            <p.Content class="w-auto overflow-hidden p-0" @align="end" @sideOffset={{8}}>
              <Calendar
                @mode="single"
                @value={{this.date}}
                @captionLayout="dropdown"
                @defaultMonth={{this.date}}
                @onValueChange={{this.select}}
              />
            </p.Content>
          </Popover>
        </g.Addon>
      </InputGroup>
      <div class="px-1 text-sm text-muted-foreground">
        Your post will be published on
        <span class="font-medium">{{formatDate this.date}}</span>.
      </div>
    </Field>
  </template>
}
