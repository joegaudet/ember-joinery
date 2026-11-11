import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import { FieldGroup } from '@ember-joinery/ember'

const frameworks = [
  { value: 'next', label: 'Next.js' },
  { value: 'sveltekit', label: 'SvelteKit' },
  { value: 'nuxt', label: 'Nuxt.js' },
  { value: 'remix', label: 'Remix' },
  { value: 'astro', label: 'Astro' },
]

/*
 * Joinery's own: a `combobox` field filters its `@options` as you type, and stores the one
 * chosen (its key, with `@storeKey`).
 */
export default class FormwrightCombobox extends Component {
  model = { framework: null as string | null }

  <template>
    <Form @model={{this.model}} @name="project" class="w-full max-w-xs" as |f|>
      <FieldGroup>
        <f.Field
          @for="framework"
          @control="combobox"
          @label="Framework"
          @placeholder="Select a framework"
          @options={{frameworks}}
          @storeKey={{true}}
        />
      </FieldGroup>
    </Form>
  </template>
}
