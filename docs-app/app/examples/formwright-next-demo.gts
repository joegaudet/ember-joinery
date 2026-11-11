import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Form } from '@ember-formwright/ember'
import { Card, Field, FieldGroup, InputGroup, Spinner, asButton, toast } from '@ember-joinery/ember'
import * as z from 'zod'

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

class BugReport {
  @tracked title = ''
  @tracked description = ''
}

/** Stands in for upstream's server action: the round trip to the server that saves it. */
function saveReport(): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, 600))
}

/*
 * Upstream's form-next-demo (its server action's form, `useActionState`), on Formwright. Its
 * `@onSubmit` returns a promise, which Formwright waits for: meanwhile `f.state.isSubmitting`
 * is true, so the fields and the button are disabled and the button shows a Spinner, as
 * upstream's `pending` does. Once it is saved, the form empties and a toast thanks you, as
 * upstream's does when its action succeeds. Upstream's server checks the schema after the
 * round trip; Formwright checks it before, so an invalid form shows its errors at once. It has
 * no Reset, as upstream's hasn't.
 */
export default class FormwrightNextDemo extends Component {
  model = new BugReport()

  onSubmit = async (report: BugReport): Promise<void> => {
    await saveReport()
    report.title = ''
    report.description = ''
    toast('Thank you for your feedback', {
      description: "We'll review your report and get back to you soon.",
    })
  }

  <template>
    <Card class="w-full max-w-md" as |c|>
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
        @onSubmit={{this.onSubmit}}
        class="contents"
        as |f|
      >
        <c.Content>
          <FieldGroup>
            <f.Field
              @for="title"
              @label="Bug Title"
              @placeholder="Login button not working on mobile"
              @disabled={{f.state.isSubmitting}}
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
              @disabled={{f.state.isSubmitting}}
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
            <f.Submit {{asButton}} @disabled={{f.state.isSubmitting}}>
              {{#if f.state.isSubmitting}}<Spinner />{{/if}}
              Submit
            </f.Submit>
          </Field>
        </c.Footer>
      </Form>
    </Card>
  </template>
}
