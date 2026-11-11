import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import { FieldGroup } from '@ember-joinery/ember'

/*
 * Joinery's own: a `date-picker` field is upstream's Date Picker, a Popover's Calendar, and
 * stores the day picked as a `Date`. `@captionLayout="dropdown"` picks the month and year from
 * lists, as upstream's date of birth example does.
 */
export default class FormwrightDatePicker extends Component {
  model = { dob: null as Date | null }

  <template>
    <Form @model={{this.model}} @name="profile" class="w-full max-w-xs" as |f|>
      <FieldGroup>
        <f.Field
          @for="dob"
          @control="date-picker"
          @label="Date of birth"
          @hint="Your date of birth is used to calculate your age."
          @placeholder="Select date"
          @locale="en-US"
          as |field|
        >
          <field.Control @captionLayout="dropdown" />
        </f.Field>
      </FieldGroup>
    </Form>
  </template>
}
