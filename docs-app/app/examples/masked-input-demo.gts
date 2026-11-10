import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldDescription, FieldGroup, FieldLabel } from '@ember-joinery/ember'
import { MaskedInput } from '@ember-joinery/maskito'

// Ported from Formwright's guide (data-maskito): a phone and a postal code mask. The postal
// code's FieldDescription is Joinery's own: a mask turns away a character with no message, so
// the guide's Accessibility notes ask for what it expects in words, and a placeholder alone
// goes once something is typed.
const phoneMask = {
  mask: ['(', /\d/, /\d/, /\d/, ')', ' ', /\d/, /\d/, /\d/, '-', /\d/, /\d/, /\d/, /\d/],
}
const postalMask = { mask: [/[A-Za-z]/, /\d/, /[A-Za-z]/, ' ', /\d/, /[A-Za-z]/, /\d/] }

export default class MaskedInputDemo extends Component {
  @tracked phone = ''
  @tracked postalCode = ''

  setPhone = (value: string) => (this.phone = value)
  setPostalCode = (value: string) => (this.postalCode = value)

  <template>
    <FieldGroup class="w-full max-w-xs">
      <Field>
        <FieldLabel for="masked-input-demo-phone">Phone</FieldLabel>
        <MaskedInput
          id="masked-input-demo-phone"
          @name="phone"
          @mask={{phoneMask}}
          @value={{this.phone}}
          @onValueChange={{this.setPhone}}
          placeholder="(555) 555-5555"
          inputmode="tel"
        />
      </Field>
      <Field>
        <FieldLabel for="masked-input-demo-postal-code">Postal code</FieldLabel>
        <MaskedInput
          id="masked-input-demo-postal-code"
          @name="postal-code"
          @mask={{postalMask}}
          @value={{this.postalCode}}
          @onValueChange={{this.setPostalCode}}
          placeholder="K1A 0B1"
          aria-describedby="masked-input-demo-postal-code-hint"
        />
        <FieldDescription id="masked-input-demo-postal-code-hint">
          A letter, a digit, a letter, then a space and the same again.
        </FieldDescription>
      </Field>
    </FieldGroup>
  </template>
}
