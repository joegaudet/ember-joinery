import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import { Card, Field, FieldGroup, asButton } from '@ember-joinery/ember'
import * as z from 'zod'
import { showSubmitted } from './formwright/submitted.gts'

const formSchema = z.object({
  about: z
    .string()
    .min(10, 'Please provide at least 10 characters.')
    .max(200, 'Please keep it under 200 characters.'),
})

/* Upstream's form-rhf-textarea (form-tanstack-textarea, form-formisch-textarea), on Formwright. */
export default class FormwrightTextarea extends Component {
  model = { about: '' }

  <template>
    <Card class="w-full sm:max-w-md" as |c|>
      <c.Header>
        <c.Title>Personalization</c.Title>
        <c.Description>
          Customize your experience by telling us more about yourself.
        </c.Description>
      </c.Header>
      <Form
        @model={{this.model}}
        @name="personalization"
        @validator={{formSchema}}
        @onSubmit={{showSubmitted}}
        class="contents"
        as |f|
      >
        <c.Content>
          <FieldGroup>
            <f.Field
              @for="about"
              @control="textarea"
              @label="More about you"
              @placeholder="I'm a software engineer..."
              @hint="Tell us more about yourself. This will be used to help us personalize your experience."
              as |field|
            >
              <field.Control class="min-h-[120px]" />
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
