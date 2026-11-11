import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import { Form, type FieldLayoutSignature } from '@ember-formwright/ember'
import {
  Button,
  Card,
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLegend,
  FieldSet,
  Icon,
  InputGroup,
  asButton,
  asField,
  asFieldContent,
} from '@ember-joinery/ember'
import { asFieldErrors } from '@ember-joinery/formwright'
import { X } from 'lucide'
import * as z from 'zod'
import { showSubmitted } from './formwright/submitted.gts'

const formSchema = z.object({
  emails: z
    .array(z.object({ address: z.string().email('Enter a valid email address.') }))
    .min(1, 'Add at least one email address.')
    .max(5, 'You can add up to 5 email addresses.'),
})

/** Each email's field: a horizontal Field whose FieldContent holds the input and its error. */
const EmailLayout: TOC<FieldLayoutSignature> = <template>
  <div {{asField orientation="horizontal" invalid=@field.isInvalid}}>
    <div {{asFieldContent}}>
      <@parts.Control as |control|>{{yield control}}</@parts.Control>
      {{#if @field.isInvalid}}
        <@parts.Errors {{asFieldErrors}} />
      {{/if}}
    </div>
  </div>
</template>

const addressPath = (index: number) => `emails.${index}.address` as const
const plusOne = (index: number) => index + 1

class Emails {
  @tracked emails = [{ address: '' }, { address: '' }]
}

/*
 * Upstream's form-rhf-array (form-tanstack-array, form-formisch-array), on Formwright. Each
 * address is a field at its index (`emails.0.address`), set out by a layout of the example's
 * own; the list's own errors (too few, too many) are the form's errors for `emails`. Upstream's
 * inputs have no label; these are named `Email address 1`, `2`…, so the audit passes.
 */
export default class FormwrightArray extends Component {
  model = new Emails()

  get canAdd(): boolean {
    return this.model.emails.length < 5
  }

  get canRemove(): boolean {
    return this.model.emails.length > 1
  }

  append = () => {
    this.model.emails = [...this.model.emails, { address: '' }]
  }

  remove = (index: number) => {
    this.model.emails = this.model.emails.filter((_, i) => i !== index)
  }

  /** The model's addresses, as upstream's toast shows them (a class's fields aren't JSON's). */
  submit = (model: Emails) => showSubmitted({ emails: model.emails })

  /** As upstream's `form.reset()`, back to its two empty addresses. */
  restore = () => {
    this.model.emails = [{ address: '' }, { address: '' }]
  }

  <template>
    <Card class="w-full sm:max-w-md" as |c|>
      <c.Header class="border-b">
        <c.Title>Contact Emails</c.Title>
        <c.Description>Manage your contact email addresses.</c.Description>
      </c.Header>
      <Form
        @model={{this.model}}
        @name="contact-emails"
        @validator={{formSchema}}
        @onSubmit={{this.submit}}
        @didReset={{this.restore}}
        class="contents"
        as |f|
      >
        <c.Content>
          <FieldSet class="gap-4">
            <FieldLegend @variant="label">Email Addresses</FieldLegend>
            <FieldDescription>
              Add up to 5 email addresses where we can contact you.
            </FieldDescription>
            <FieldGroup class="gap-4">
              {{#each this.model.emails key="@index" as |_email index|}}
                <f.Field
                  @for={{addressPath index}}
                  @control="email"
                  @placeholder="name@example.com"
                  @layout={{EmailLayout}}
                  as |field|
                >
                  <InputGroup as |g|>
                    <field.Control
                      @group={{g}}
                      @autocomplete="email"
                      aria-label="Email address {{plusOne index}}"
                    />
                    {{#if this.canRemove}}
                      <g.Addon @align="inline-end">
                        <g.Button
                          @variant="ghost"
                          @size="icon-xs"
                          aria-label="Remove email {{plusOne index}}"
                          {{on "click" (fn this.remove index)}}
                        >
                          <Icon @icon={{X}} />
                        </g.Button>
                      </g.Addon>
                    {{/if}}
                  </InputGroup>
                </f.Field>
              {{/each}}
              <Button
                @variant="outline"
                @size="sm"
                disabled={{if this.canAdd false true}}
                {{on "click" this.append}}
              >
                Add Email Address
              </Button>
            </FieldGroup>
            {{#each f.state.errors.emails as |message|}}
              <FieldError>{{message}}</FieldError>
            {{/each}}
          </FieldSet>
        </c.Content>
        <c.Footer class="border-t">
          <Field @orientation="horizontal">
            <f.Reset {{asButton variant="outline"}}>Reset</f.Reset>
            <f.Submit {{asButton}}>Save</f.Submit>
          </Field>
        </c.Footer>
      </Form>
    </Card>
  </template>
}
