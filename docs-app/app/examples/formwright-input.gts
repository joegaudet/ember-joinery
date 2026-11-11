import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import { Card, Field, FieldGroup, asButton } from '@ember-joinery/ember'
import * as z from 'zod'
import { showSubmitted } from './formwright/submitted.gts'

const formSchema = z.object({
  username: z
    .string()
    .min(3, 'Username must be at least 3 characters.')
    .max(10, 'Username must be at most 10 characters.')
    .regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores.'),
})

/* Upstream's form-rhf-input (form-tanstack-input, form-formisch-input), on Formwright. */
export default class FormwrightInput extends Component {
  model = { username: '' }

  <template>
    <Card class="w-full sm:max-w-md" as |c|>
      <c.Header>
        <c.Title>Profile Settings</c.Title>
        <c.Description>
          Update your profile information below.
        </c.Description>
      </c.Header>
      <Form
        @model={{this.model}}
        @name="profile"
        @validator={{formSchema}}
        @onSubmit={{showSubmitted}}
        class="contents"
        as |f|
      >
        <c.Content>
          <FieldGroup>
            <f.Field
              @for="username"
              @label="Username"
              @placeholder="shadcn"
              @hint="This is your public display name. Must be between 3 and 10 characters. Must only contain letters, numbers, and underscores."
              as |field|
            >
              <field.Control @autocomplete="username" />
            </f.Field>
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
