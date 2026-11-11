import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import { Card, Field, FieldGroup, asButton } from '@ember-joinery/ember'
import * as z from 'zod'
import { showSubmitted } from './formwright/submitted.gts'

const spokenLanguages = [
  { label: 'English', value: 'en' },
  { label: 'Spanish', value: 'es' },
  { label: 'French', value: 'fr' },
  { label: 'German', value: 'de' },
  { label: 'Italian', value: 'it' },
  { label: 'Chinese', value: 'zh' },
  { label: 'Japanese', value: 'ja' },
] as const

const formSchema = z.object({
  language: z
    .string()
    .min(1, 'Please select your spoken language.')
    .refine(val => val !== 'auto', {
      message: 'Auto-detection is not allowed. Please select a specific language.',
    }),
})

/*
 * Upstream's form-rhf-select (form-tanstack-select, form-formisch-select), on Formwright. The
 * field is responsive (`joinery-responsive`): its label, hint and error in a FieldContent, the
 * Select beside them once the group is wide enough. The control's block writes the items, as
 * upstream's do, with Auto and a separator ahead of the languages.
 */
export default class FormwrightSelect extends Component {
  model = { language: '' }

  <template>
    <Card class="w-full sm:max-w-lg" as |c|>
      <c.Header>
        <c.Title>Language Preferences</c.Title>
        <c.Description>
          Select your preferred spoken language.
        </c.Description>
      </c.Header>
      <Form
        @model={{this.model}}
        @name="language-preferences"
        @validator={{formSchema}}
        @onSubmit={{showSubmitted}}
        class="contents"
        as |f|
      >
        <c.Content>
          <FieldGroup>
            <f.Field
              @for="language"
              @control="select"
              @label="Spoken Language"
              @hint="For best results, select the language you speak."
              @placeholder="Select"
              @options={{spokenLanguages}}
              @storeKey={{true}}
              @layout="joinery-responsive"
              as |field|
            >
              <field.Control class="min-w-[120px]" as |s|>
                <s.Item @value="auto">Auto</s.Item>
                <s.Separator />
                {{#each spokenLanguages as |language|}}
                  <s.Item @value={{language.value}}>{{language.label}}</s.Item>
                {{/each}}
              </field.Control>
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
