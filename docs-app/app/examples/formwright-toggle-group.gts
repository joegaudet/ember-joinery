import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Bold, Italic, Underline } from 'lucide'
import { Form } from '@ember-formwright/ember'
import { FieldGroup, Icon } from '@ember-joinery/ember'

const sizes = [
  { id: 'sm', label: 'Small' },
  { id: 'md', label: 'Medium' },
  { id: 'lg', label: 'Large' },
]

const marks = [
  { id: 'bold', label: 'Bold', icon: Bold },
  { id: 'italic', label: 'Italic', icon: Italic },
  { id: 'underline', label: 'Underline', icon: Underline },
]

class Text {
  @tracked size: string | null = 'md'
  @tracked marks = ['bold']
  @tracked smallCaps = false
}

/*
 * Joinery's own: a `toggle-group` field stores the option pressed, or, when its value is a
 * list, the options pressed; its legend names the group. A `toggle` field stores whether it
 * is pressed. The control's block draws each item (an icon, which its option's label names).
 */
export default class FormwrightToggleGroup extends Component {
  model = new Text()

  <template>
    <Form @model={{this.model}} @name="text" class="w-full max-w-xs" as |f|>
      <FieldGroup>
        <f.Field
          @for="size"
          @control="toggle-group"
          @label="Size"
          @options={{sizes}}
          @storeKey={{true}}
          as |field|
        >
          <field.Control @variant="outline" />
        </f.Field>
        <f.Field
          @for="marks"
          @control="toggle-group"
          @label="Marks"
          @options={{marks}}
          @storeKey={{true}}
          as |field|
        >
          <field.Control @variant="outline" as |mark|>
            <Icon @icon={{mark.icon}} />
          </field.Control>
        </f.Field>
        <f.Field @for="smallCaps" @control="toggle" @label="Small caps" as |field|>
          <field.Control @variant="outline">Aa</field.Control>
        </f.Field>
      </FieldGroup>
    </Form>
  </template>
}
