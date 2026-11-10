import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import {
  Field,
  FieldContent,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  Select,
  Switch,
} from '@ember-joinery/ember'

export default class SelectAlignItem extends Component {
  @tracked alignItemWithTrigger = true

  setAlignItemWithTrigger = (checked: boolean) => {
    this.alignItemWithTrigger = checked
  }

  get position(): 'item-aligned' | 'popper' {
    return this.alignItemWithTrigger ? 'item-aligned' : 'popper'
  }

  <template>
    <FieldGroup class="w-full max-w-xs">
      <Field @orientation="horizontal">
        <FieldContent>
          <FieldLabel for="align-item">Align Item</FieldLabel>
          <FieldDescription>
            Toggle to align the item with the trigger.
          </FieldDescription>
        </FieldContent>
        <Switch
          id="align-item"
          @checked={{this.alignItemWithTrigger}}
          @onCheckedChange={{this.setAlignItemWithTrigger}}
        />
      </Field>
      <Field>
        {{! Named with aria-label: a combobox isn't named by its text, and upstream's has no label. }}
        <Select @defaultValue="banana" as |s|>
          <s.Trigger aria-label="Fruit">
            <s.Value />
          </s.Trigger>
          <s.Content @position={{this.position}}>
            <s.Group>
              <s.Item @value="apple">Apple</s.Item>
              <s.Item @value="banana">Banana</s.Item>
              <s.Item @value="blueberry">Blueberry</s.Item>
              <s.Item @value="grapes">Grapes</s.Item>
              <s.Item @value="pineapple">Pineapple</s.Item>
            </s.Group>
          </s.Content>
        </Select>
      </Field>
    </FieldGroup>
  </template>
}
