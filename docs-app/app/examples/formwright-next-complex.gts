import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Form } from '@ember-formwright/ember'
import {
  Card,
  Field,
  FieldGroup,
  FieldSeparator,
  Spinner,
  asButton,
  toast,
} from '@ember-joinery/ember'
import * as z from 'zod'

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

// Upstream's schema (form-next-complex-schema.ts) is zod 3's; zod 4 names `required_error` `error`.
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

class Subscription {
  @tracked plan = 'basic'
  @tracked billingPeriod = 'monthly'
  @tracked addons: string[] = []
  @tracked emailNotifications = false
}

/** Stands in for upstream's server action, which sleeps for a second before it saves. */
function savePreferences(): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, 1000))
}

/*
 * Upstream's form-next-complex (its server action's form, `useActionState`), on Formwright.
 * It is the complex form's fields, but not its card: there is no header, the billing period
 * starts as Monthly, the plan's legend is a section's (FieldLegend's default variant), and the
 * footer is one button at the end. Its `@onSubmit` returns a promise, which Formwright waits
 * for: meanwhile `f.state.isSubmitting` is true, so every field and the button are disabled
 * and the button shows a Spinner, as upstream's `pending` does. Once it is saved, a success
 * toast says so, and the form keeps what was saved, as upstream's action returns it. Upstream's
 * server checks the schema after the round trip; Formwright checks it before, so an invalid
 * form shows its errors at once. Upstream's button sits outside its `<form>` and names it
 * (`form="subscription-form"`); here the form wraps the card's content and footer (`contents`,
 * so it takes no box), and the button is in it.
 */
export default class FormwrightNextComplex extends Component {
  model = new Subscription()

  onSubmit = async (): Promise<void> => {
    await savePreferences()
    toast.success('Preferences saved', {
      description: 'Your subscription plan has been updated.',
    })
  }

  <template>
    <Card class="w-full max-w-sm" as |c|>
      <Form
        @model={{this.model}}
        @name="subscription-form"
        @validator={{formSchema}}
        @onSubmit={{this.onSubmit}}
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
              @disabled={{f.state.isSubmitting}}
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
              @disabled={{f.state.isSubmitting}}
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
              @disabled={{f.state.isSubmitting}}
            />
            <FieldSeparator />
            <f.Field
              @for="emailNotifications"
              @control="switch"
              @label="Email Notifications"
              @hint="Receive email updates about your subscription"
              @disabled={{f.state.isSubmitting}}
            />
          </FieldGroup>
        </c.Content>
        <c.Footer>
          <Field @orientation="horizontal" class="justify-end">
            <f.Submit {{asButton}} @disabled={{f.state.isSubmitting}}>
              {{#if f.state.isSubmitting}}<Spinner />{{/if}}
              Save Preferences
            </f.Submit>
          </Field>
        </c.Footer>
      </Form>
    </Card>
  </template>
}
