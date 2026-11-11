import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import { Card, Field, FieldGroup, FieldSeparator, asButton } from '@ember-joinery/ember'
import { JoineryFieldLayout } from '@ember-joinery/formwright'
import * as z from 'zod'
import { showSubmitted } from './formwright/submitted.gts'

const plans = [
  { id: 'basic', title: 'Basic', description: 'For individuals and small teams' },
  { id: 'pro', title: 'Pro', description: 'For businesses with higher demands' },
] as const

const billingPeriods = [
  { id: 'monthly', label: 'Monthly' },
  { id: 'yearly', label: 'Yearly' },
] as const

const addons = [
  { id: 'analytics', title: 'Analytics', description: 'Advanced analytics and reporting' },
  { id: 'backup', title: 'Backup', description: 'Automated daily backups' },
  { id: 'support', title: 'Priority Support', description: '24/7 premium customer support' },
] as const

// Upstream's schema is zod 3's; zod 4 names `required_error` `error`.
const formSchema = z.object({
  plan: z
    .string({ error: 'Please select a subscription plan' })
    .min(1, 'Please select a subscription plan')
    .refine(value => value === 'basic' || value === 'pro', {
      message: 'Invalid plan selection. Please choose Basic or Pro',
    }),
  billingPeriod: z
    .string({ error: 'Please select a billing period' })
    .min(1, 'Please select a billing period'),
  addons: z
    .array(z.string())
    .min(1, 'Please select at least one add-on')
    .max(3, 'You can select up to 3 add-ons')
    .refine(value => value.every(addon => addons.some(a => a.id === addon)), {
      message: 'You selected an invalid add-on',
    }),
  emailNotifications: z.boolean(),
})

/*
 * Upstream's form-rhf-complex (and form-tanstack-complex and form-formisch-complex, the same
 * form in the other two libraries), on Formwright: a radio field of cards, a select, a
 * checkbox group whose choices have descriptions, and a switch. The switch's error goes in its
 * FieldContent, as every horizontal field's does here (upstream puts that one after the switch).
 * form-next-complex is another form on the same fields: formwright-next-complex.
 */
export default class FormwrightComplex extends Component {
  model = { plan: 'basic', billingPeriod: '', addons: [] as string[], emailNotifications: false }

  <template>
    <Card class="w-full max-w-sm" as |c|>
      <c.Header class="border-b">
        <c.Title>You're almost there!</c.Title>
        <c.Description>
          Choose your subscription plan and billing period.
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
              @label="Subscription Plan"
              @hint="Choose your subscription plan."
              @options={{plans}}
              @optionLabel="title"
              @storeKey={{true}}
              @layout={{component JoineryFieldLayout legend="label"}}
              as |field|
            >
              <field.Control @variant="card" />
            </f.Field>
            <FieldSeparator />
            <f.Field
              @for="billingPeriod"
              @control="select"
              @label="Billing Period"
              @hint="Choose how often you want to be billed."
              @placeholder="Select"
              @options={{billingPeriods}}
              @storeKey={{true}}
            />
            <FieldSeparator />
            <f.Field
              @for="addons"
              @control="checkbox-group"
              @label="Add-ons"
              @hint="Select additional features you'd like to include."
              @options={{addons}}
              @optionLabel="title"
              @storeKey={{true}}
            />
            <FieldSeparator />
            <f.Field
              @for="emailNotifications"
              @control="switch"
              @label="Email Notifications"
              @hint="Receive email updates about your subscription"
            />
          </FieldGroup>
        </c.Content>
        <c.Footer class="border-t">
          <Field>
            <f.Submit {{asButton}}>Save Preferences</f.Submit>
            <f.Reset {{asButton variant="outline"}}>Reset</f.Reset>
          </Field>
        </c.Footer>
      </Form>
    </Card>
  </template>
}
