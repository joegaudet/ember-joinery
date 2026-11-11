import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Button, Calendar, Field, FieldLabel, Popover } from '@ember-joinery/ember'

const toLocaleDateString = (date: Date) => date.toLocaleDateString()

export default class DatePickerSimple extends Component {
  @tracked open = false
  @tracked date: Date | undefined = undefined

  setOpen = (open: boolean) => (this.open = open)

  select = (date: Date | undefined) => {
    this.date = date
    this.open = false
  }

  <template>
    <Field class="mx-auto w-44">
      <FieldLabel for="date">Date of birth</FieldLabel>
      <Popover @open={{this.open}} @onOpenChange={{this.setOpen}} as |p|>
        <Button @variant="outline" id="date" class="justify-start font-normal" {{p.trigger}}>
          {{#if this.date}}{{toLocaleDateString this.date}}{{else}}Select date{{/if}}
        </Button>
        <p.Content class="w-auto overflow-hidden p-0" @align="start">
          <Calendar
            @mode="single"
            @value={{this.date}}
            @defaultMonth={{this.date}}
            @captionLayout="dropdown"
            @onValueChange={{this.select}}
          />
        </p.Content>
      </Popover>
    </Field>
  </template>
}
