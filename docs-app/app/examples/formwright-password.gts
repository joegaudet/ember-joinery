import Component from '@glimmer/component'
import { Check } from 'lucide'
import { Form } from '@ember-formwright/ember'
import { Card, Field, FieldGroup, Icon, InputGroup, Progress, asButton } from '@ember-joinery/ember'
import * as z from 'zod'
import { showSubmitted } from './formwright/submitted.gts'

const passwordRequirements = [
  { id: 'length', label: 'At least 8 characters', test: (val: string) => val.length >= 8 },
  { id: 'lowercase', label: 'One lowercase letter', test: (val: string) => /[a-z]/.test(val) },
  { id: 'uppercase', label: 'One uppercase letter', test: (val: string) => /[A-Z]/.test(val) },
  { id: 'number', label: 'One number', test: (val: string) => /\d/.test(val) },
  {
    id: 'special',
    label: 'One special character',
    test: (val: string) => /[!@#$%^&*(),.?":{}|<>]/.test(val),
  },
]

const formSchema = z.object({
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .refine(val => /[a-z]/.test(val), 'Password must contain at least one lowercase letter')
    .refine(val => /[A-Z]/.test(val), 'Password must contain at least one uppercase letter')
    .refine(val => /\d/.test(val), 'Password must contain at least one number')
    .refine(
      val => /[!@#$%^&*(),.?":{}|<>]/.test(val),
      'Password must contain at least one special character',
    ),
})

/** The share of the requirements a password meets, out of 100. */
function strengthOf(password: string): number {
  const met = passwordRequirements.filter(requirement => requirement.test(password))
  return (met.length / passwordRequirements.length) * 100
}

/** Upstream's strength colours. */
function strengthColor(password: string): string {
  const strength = strengthOf(password)
  if (strength === 0) return 'bg-neutral-200'
  if (strength <= 40) return 'bg-red-500'
  if (strength <= 80) return 'bg-yellow-500'
  return 'bg-green-500'
}

const allMet = (password: string) => strengthOf(password) === 100
const isMet = (requirement: (typeof passwordRequirements)[number], password: string) =>
  requirement.test(password)

/*
 * Upstream's form-rhf-password, on Formwright. The strength meter and the list of
 * requirements read the field's value as it is typed (the block's `field.value`), and sit
 * between the input and its errors, as upstream's do. Its Progress is named, which upstream's
 * isn't, so the audit passes.
 */
export default class FormwrightPassword extends Component {
  model = { password: '' }

  <template>
    <Card class="w-full sm:max-w-md" as |c|>
      <c.Header class="border-b">
        <c.Title>Create Password</c.Title>
        <c.Description>
          Choose a strong password to secure your account.
        </c.Description>
      </c.Header>
      <Form
        @model={{this.model}}
        @name="create-password"
        @validator={{formSchema}}
        @onSubmit={{showSubmitted}}
        class="contents"
        as |f|
      >
        <c.Content>
          <FieldGroup>
            <f.Field
              @for="password"
              @control="password"
              @label="Password"
              @placeholder="Enter your password"
              as |field|
            >
              <InputGroup as |g|>
                <field.Control @group={{g}} @autocomplete="new-password" />
                <g.Addon @align="inline-end">
                  <Icon
                    @icon={{Check}}
                    class={{if (allMet field.value) "text-green-500" "text-muted-foreground"}}
                  />
                </g.Addon>
              </InputGroup>
              {{! Password strength meter. }}
              <div class="space-y-2">
                <Progress
                  @value={{strengthOf field.value}}
                  class={{strengthColor field.value}}
                  aria-label="Password strength"
                />
                {{! Requirements list. }}
                <div class="space-y-1.5">
                  {{#each passwordRequirements as |requirement|}}
                    <div class="flex items-center gap-2 text-sm">
                      <Icon
                        @icon={{Check}}
                        class={{if
                          (isMet requirement field.value)
                          "size-4 text-green-500"
                          "size-4 text-muted-foreground"
                        }}
                      />
                      <span
                        class={{if
                          (isMet requirement field.value)
                          "text-foreground"
                          "text-muted-foreground"
                        }}
                      >
                        {{requirement.label}}
                      </span>
                    </div>
                  {{/each}}
                </div>
              </div>
            </f.Field>
          </FieldGroup>
        </c.Content>
        <c.Footer class="border-t">
          <Field>
            <f.Submit {{asButton}}>Create Password</f.Submit>
            <f.Reset {{asButton variant="outline"}}>Reset</f.Reset>
          </Field>
        </c.Footer>
      </Form>
    </Card>
  </template>
}
