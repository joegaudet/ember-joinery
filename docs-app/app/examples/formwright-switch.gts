import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import { Card, Field, FieldGroup, asButton } from '@ember-joinery/ember'
import * as z from 'zod'
import { showSubmitted } from './formwright/submitted.gts'

const formSchema = z.object({
  twoFactor: z.boolean().refine(val => val === true, {
    message: 'It is highly recommended to enable two-factor authentication.',
  }),
})

/*
 * Upstream's form-rhf-switch (form-tanstack-switch, form-formisch-switch), on Formwright. A
 * switch's field is horizontal: its label, hint and error in a FieldContent, then the switch.
 */
export default class FormwrightSwitch extends Component {
  model = { twoFactor: false }

  <template>
    <Card class="w-full sm:max-w-md" as |c|>
      <c.Header>
        <c.Title>Security Settings</c.Title>
        <c.Description>
          Manage your account security preferences.
        </c.Description>
      </c.Header>
      <Form
        @model={{this.model}}
        @name="security"
        @validator={{formSchema}}
        @onSubmit={{showSubmitted}}
        class="contents"
        as |f|
      >
        <c.Content>
          <FieldGroup>
            <f.Field
              @for="twoFactor"
              @control="switch"
              @label="Multi-factor authentication"
              @hint="Enable multi-factor authentication to secure your account."
            />
          </FieldGroup>
        </c.Content>
        <c.Footer>
          <Field @orientation="horizontal">
            <f.Reset {{asButton variant="outline"}}>Reset</f.Reset>
            <f.Submit {{asButton}}>Save</f.Submit>
          </Field>
        </c.Footer>
      </Form>
    </Card>
  </template>
}
