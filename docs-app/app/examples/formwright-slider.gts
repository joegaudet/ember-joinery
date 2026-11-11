import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Form } from '@ember-formwright/ember'
import { FieldGroup } from '@ember-joinery/ember'

class Filters {
  @tracked volume = 50
  @tracked price = [200, 800]
}

/*
 * Joinery's own: a `slider` field stores a number, and a `range` field (or a slider whose
 * value is a list) one number for each thumb. Each thumb is named after the field's label.
 */
export default class FormwrightSlider extends Component {
  model = new Filters()

  <template>
    <Form @model={{this.model}} @name="filters" class="w-full max-w-xs" as |f|>
      <FieldGroup>
        <f.Field
          @for="volume"
          @control="slider"
          @label="Volume"
          @hint="Turn it up in steps of ten."
          @step={{10}}
        />
        <f.Field
          @for="price"
          @control="range"
          @label="Price"
          @hint="Between $0 and $1,000."
          @min={{0}}
          @max={{1000}}
          @step={{10}}
        />
      </FieldGroup>
    </Form>
  </template>
}
