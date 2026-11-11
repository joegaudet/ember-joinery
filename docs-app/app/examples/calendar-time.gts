import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Clock2 } from 'lucide'
import {
  Calendar,
  Card,
  Field,
  FieldGroup,
  FieldLabel,
  Icon,
  InputGroup,
} from '@ember-joinery/ember'

export default class CalendarWithTime extends Component {
  @tracked date: Date | undefined = new Date(new Date().getFullYear(), new Date().getMonth(), 12)

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    <Card @size="sm" class="mx-auto w-fit" as |c|>
      <c.Content>
        <Calendar @mode="single" @value={{this.date}} @onValueChange={{this.setDate}} class="p-0" />
      </c.Content>
      <c.Footer class="border-t bg-card">
        <FieldGroup>
          <Field>
            <FieldLabel for="time-from">Start Time</FieldLabel>
            <InputGroup as |g|>
              <g.Input
                id="time-from"
                type="time"
                step="1"
                @defaultValue="10:30:00"
                class="appearance-none [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
              />
              <g.Addon>
                <Icon @icon={{Clock2}} class="text-muted-foreground" />
              </g.Addon>
            </InputGroup>
          </Field>
          <Field>
            <FieldLabel for="time-to">End Time</FieldLabel>
            <InputGroup as |g|>
              <g.Input
                id="time-to"
                type="time"
                step="1"
                @defaultValue="12:30:00"
                class="appearance-none [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
              />
              <g.Addon>
                <Icon @icon={{Clock2}} class="text-muted-foreground" />
              </g.Addon>
            </InputGroup>
          </Field>
        </FieldGroup>
      </c.Footer>
    </Card>
  </template>
}
