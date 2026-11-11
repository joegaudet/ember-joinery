import Component from '@glimmer/component'
import { array } from '@ember/helper'
import { Form, type ErrorMap } from '@ember-formwright/ember'
import { FieldGroup, REGEXP_ONLY_DIGITS, asButton } from '@ember-joinery/ember'

const validate = (model: { code: string }): ErrorMap =>
  model.code.length === 6 ? {} : { code: ['Enter all six digits.'] }

/*
 * Joinery's own: an `input-otp` field stores the code as a string, in `@maxLength` slots;
 * `@groups` splits them with a separator, and `@pattern` limits what they take.
 */
export default class FormwrightInputOtp extends Component {
  model = { code: '' }

  <template>
    <Form
      @model={{this.model}}
      @name="verify"
      @validator={{validate}}
      class="flex w-full max-w-xs flex-col gap-4"
      as |f|
    >
      <FieldGroup>
        <f.Field
          @for="code"
          @control="input-otp"
          @label="Verification code"
          @hint="Enter the six digits we sent to your phone."
          @maxLength={{6}}
          as |field|
        >
          <field.Control @groups={{array 3 3}} @pattern={{REGEXP_ONLY_DIGITS}} />
        </f.Field>
      </FieldGroup>
      <f.Submit {{asButton}}>Verify</f.Submit>
    </Form>
  </template>
}
