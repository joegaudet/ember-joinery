import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import {
  Card,
  Field,
  FieldDescription,
  FieldGroup,
  FieldLegend,
  FieldSeparator,
  FieldSet,
  asButton,
} from '@ember-joinery/ember'
import { JoineryFieldLayout } from '@ember-joinery/formwright'
import * as z from 'zod'
import { showSubmitted } from './formwright/submitted.gts'

const tasks = [
  { id: 'push', label: 'Push notifications' },
  { id: 'email', label: 'Email notifications' },
] as const

const formSchema = z.object({
  responses: z.boolean(),
  tasks: z
    .array(z.string())
    .min(1, 'Please select at least one notification type.')
    .refine(value => value.every(task => tasks.some(t => t.id === task)), {
      message: 'Invalid notification type selected.',
    }),
})

/*
 * Upstream's form-rhf-checkbox (form-tanstack-checkbox, form-formisch-checkbox), on Formwright.
 * Responses is one checkbox, under a legend and a description of its own, as upstream's is.
 * Tasks is a `checkbox-group` field: its FieldSet, legend, description and checkboxes are the
 * layout's and the control's, and its error goes inside its FieldSet (upstream puts it after).
 */
export default class FormwrightCheckbox extends Component {
  model = { responses: true, tasks: [] as string[] }

  <template>
    <Card class="w-full sm:max-w-md" as |c|>
      <c.Header>
        <c.Title>Notifications</c.Title>
        <c.Description>Manage your notification preferences.</c.Description>
      </c.Header>
      <Form
        @model={{this.model}}
        @name="notifications"
        @validator={{formSchema}}
        @onSubmit={{showSubmitted}}
        class="contents"
        as |f|
      >
        <c.Content>
          <FieldGroup>
            <FieldSet>
              <FieldLegend @variant="label">Responses</FieldLegend>
              <FieldDescription>
                Get notified for requests that take time, like research or image generation.
              </FieldDescription>
              <FieldGroup data-slot="checkbox-group">
                <f.Field
                  @for="responses"
                  @control="checkbox"
                  @label="Push notifications"
                  @disabled={{true}}
                  @layout={{component JoineryFieldLayout labelClass="font-normal"}}
                />
              </FieldGroup>
            </FieldSet>
            <FieldSeparator />
            <f.Field
              @for="tasks"
              @control="checkbox-group"
              @label="Tasks"
              @hint="Get notified when tasks you've created have updates."
              @options={{tasks}}
              @storeKey={{true}}
              @layout={{component JoineryFieldLayout legend="label"}}
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
