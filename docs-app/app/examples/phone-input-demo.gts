import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import {
  Button,
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from '@ember-joinery/ember'
import { PhoneInput, isValidPhone } from '@ember-joinery/maskito'

// Ported from Formwright's guide (controls-phone): three phone numbers, stored in E.164 form,
// shown formatted, and checked with isValidPhone when the form is saved. Formwright's zod schema
// becomes errorFor() below, as Joinery's components take no validator.
//
// Formwright's office field is `@strict={{false}}`: having no country picker, it takes any
// country's number typed from its `+`. A PhoneInput always has a picker, which chooses the
// country, so it has no such mode: the mask keeps the calling code shown in front, and another
// country comes from the picker, or from a number with its `+` pasted, dropped or autofilled.
// The office field's hint says so, where Formwright's says "Any country: start with +".
//
// The UK mobile's placeholder is +44 7400 123456, not Formwright's +44 7700 900123: that one is in
// Ofcom's range for drama, which libphonenumber-js reads as no number, so a reader who typed the
// placeholder in would be told "That number looks off".
export class Contact {
  @tracked phone: string | null = '+12125550123'
  @tracked mobile: string | null = null
  @tracked office: string | null = null
}

type NumberName = 'phone' | 'mobile' | 'office'

const LOOKS_OFF = 'That number looks off'

export default class PhoneInputDemo extends Component<{ Args: { contact?: Contact } }> {
  contact = this.args.contact ?? new Contact()
  /** Whether the form was saved once: from then on, each number is checked as it changes. */
  @tracked submitted = false

  setPhone = (value: string | null) => (this.contact.phone = value)
  setMobile = (value: string | null) => (this.contact.mobile = value)
  setOffice = (value: string | null) => (this.contact.office = value)

  /** The phone is required; the mobile and office numbers only have to be valid if given. */
  errorFor(name: NumberName): string | undefined {
    if (!this.submitted) return undefined
    const value = this.contact[name]
    if (name !== 'phone' && value === null) return undefined
    return isValidPhone(value) ? undefined : LOOKS_OFF
  }

  get phoneError() {
    return this.errorFor('phone')
  }

  get mobileError() {
    return this.errorFor('mobile')
  }

  get officeError() {
    return this.errorFor('office')
  }

  save = (event: SubmitEvent) => {
    event.preventDefault()
    this.submitted = true
  }

  <template>
    <form class="w-full max-w-sm" novalidate {{on "submit" this.save}}>
      <FieldGroup>
        <Field @invalid={{if this.phoneError true}}>
          <FieldLabel for="phone-input-demo-phone">Phone</FieldLabel>
          <PhoneInput
            id="phone-input-demo-phone"
            @name="phone"
            @value={{this.contact.phone}}
            @onValueChange={{this.setPhone}}
            required
            aria-invalid={{if this.phoneError "true"}}
            aria-describedby={{if this.phoneError "phone-input-demo-phone-error"}}
          />
          {{#if this.phoneError}}
            <FieldError id="phone-input-demo-phone-error">{{this.phoneError}}</FieldError>
          {{/if}}
        </Field>
        <Field @invalid={{if this.mobileError true}}>
          <FieldLabel for="phone-input-demo-mobile">UK mobile</FieldLabel>
          <PhoneInput
            id="phone-input-demo-mobile"
            @name="mobile"
            @defaultCountry="GB"
            @value={{this.contact.mobile}}
            @onValueChange={{this.setMobile}}
            placeholder="+44 7400 123456"
            aria-invalid={{if this.mobileError "true"}}
            aria-describedby={{if this.mobileError "phone-input-demo-mobile-error"}}
          />
          {{#if this.mobileError}}
            <FieldError id="phone-input-demo-mobile-error">{{this.mobileError}}</FieldError>
          {{/if}}
        </Field>
        <Field @invalid={{if this.officeError true}}>
          <FieldLabel for="phone-input-demo-office">Office</FieldLabel>
          <PhoneInput
            id="phone-input-demo-office"
            @name="office"
            @value={{this.contact.office}}
            @onValueChange={{this.setOffice}}
            placeholder="+33 6 12-34-56-78"
            aria-invalid={{if this.officeError "true"}}
            aria-describedby={{if
              this.officeError
              "phone-input-demo-office-error"
              "phone-input-demo-office-hint"
            }}
          />
          {{#if this.officeError}}
            <FieldError id="phone-input-demo-office-error">{{this.officeError}}</FieldError>
          {{else}}
            <FieldDescription id="phone-input-demo-office-hint">
              Any country: pick it, or paste a number that starts with +.
            </FieldDescription>
          {{/if}}
        </Field>
        <Button type="submit" @name="save">Save</Button>
      </FieldGroup>
    </form>
  </template>
}
