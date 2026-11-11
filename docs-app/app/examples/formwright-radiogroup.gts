import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import { Card, Field, FieldGroup, asButton } from '@ember-joinery/ember'
import * as z from 'zod'
import { showSubmitted } from './formwright/submitted.gts'

const plans = [
  {
    id: 'starter',
    title: 'Starter (100K tokens/month)',
    description: 'For everyday use with basic features.',
  },
  {
    id: 'pro',
    title: 'Pro (1M tokens/month)',
    description: 'For advanced AI usage with more features.',
  },
  {
    id: 'enterprise',
    title: 'Enterprise (Unlimited tokens)',
    description: 'For large teams and heavy usage.',
  },
] as const

const formSchema = z.object({
  plan: z.string().min(1, 'You must select a subscription plan to continue.'),
})

/*
 * Upstream's form-rhf-radiogroup (form-tanstack-radiogroup, form-formisch-radiogroup), on
 * Formwright: a `radio` field, its choices cards (`@variant="card"`) with each plan's title
 * and description.
 */
export default class FormwrightRadiogroup extends Component {
  model = { plan: '' }

  <template>
    <Card class="w-full sm:max-w-md" as |c|>
      <c.Header>
        <c.Title>Subscription Plan</c.Title>
        <c.Description>
          See pricing and features for each plan.
        </c.Description>
      </c.Header>
      <Form
        @model={{this.model}}
        @name="subscription"
        @validator={{formSchema}}
        @onSubmit={{showSubmitted}}
        class="contents"
        as |f|
      >
        <c.Content>
          <FieldGroup>
            <f.Field
              @for="plan"
              @control="radio"
              @label="Plan"
              @hint="You can upgrade or downgrade your plan at any time."
              @options={{plans}}
              @optionLabel="title"
              @storeKey={{true}}
              as |field|
            >
              <field.Control @variant="card" />
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
