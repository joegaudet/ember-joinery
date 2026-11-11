import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import { Card, Field, FieldGroup, InputGroup, asButton } from '@ember-joinery/ember'
import * as z from 'zod'
import { showSubmitted } from './formwright/submitted.gts'

const formSchema = z.object({
  title: z
    .string()
    .min(5, 'Bug title must be at least 5 characters.')
    .max(32, 'Bug title must be at most 32 characters.'),
  description: z
    .string()
    .min(20, 'Description must be at least 20 characters.')
    .max(100, 'Description must be at most 100 characters.'),
})

/*
 * Upstream's form-rhf-demo (and form-tanstack-demo, form-formisch-demo and form-next-demo, the
 * same form), on Formwright. The form wraps the card's content and footer, so its Reset and
 * Submit are its own (`f.Reset`, `f.Submit`, drawn as Joinery's Button with `asButton`);
 * `class="contents"` keeps the card's own spacing between them.
 */
export default class FormwrightDemo extends Component {
  model = { title: '', description: '' }

  <template>
    <Card class="w-full sm:max-w-md" as |c|>
      <c.Header>
        <c.Title>Bug Report</c.Title>
        <c.Description>
          Help us improve by reporting bugs you encounter.
        </c.Description>
      </c.Header>
      <Form
        @model={{this.model}}
        @name="bug-report"
        @validator={{formSchema}}
        @onSubmit={{showSubmitted}}
        class="contents"
        as |f|
      >
        <c.Content>
          <FieldGroup>
            <f.Field
              @for="title"
              @label="Bug Title"
              @placeholder="Login button not working on mobile"
              as |field|
            >
              <field.Control @autocomplete="off" />
            </f.Field>
            <f.Field
              @for="description"
              @control="textarea"
              @label="Description"
              @placeholder="I'm having an issue with the login button on mobile."
              @hint="Include steps to reproduce, expected behavior, and what actually happened."
              as |field|
            >
              <InputGroup as |g|>
                <field.Control @group={{g}} @rows={{6}} class="min-h-24 resize-none" />
                <g.Addon @align="block-end">
                  <g.Text class="tabular-nums">
                    {{field.value.length}}/100 characters
                  </g.Text>
                </g.Addon>
              </InputGroup>
            </f.Field>
          </FieldGroup>
        </c.Content>
        <c.Footer>
          <Field @orientation="horizontal">
            <f.Reset {{asButton variant="outline"}}>Reset</f.Reset>
            <f.Submit {{asButton}}>Submit</f.Submit>
          </Field>
        </c.Footer>
      </Form>
    </Card>
  </template>
}
