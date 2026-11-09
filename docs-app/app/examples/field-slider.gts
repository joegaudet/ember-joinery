import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldDescription, FieldTitle, Slider } from '@ember-joinery/ember'

export default class FieldSlider extends Component {
  @tracked value = [200, 800]

  setValue = (value: number[]) => (this.value = value)

  <template>
    <Field class="w-full max-w-xs">
      <FieldTitle>Price Range</FieldTitle>
      <FieldDescription>
        Set your budget range ($<span class="font-medium tabular-nums">{{this.value.[0]}}</span>
        -
        <span class="font-medium tabular-nums">{{this.value.[1]}}</span>).
      </FieldDescription>
      {{!
        Upstream's puts aria-label on the slider's root, a <span> with no role, where it names
        nothing and fails the audit; role="group" gives the name a home. Its thumbs are
        Minimum and Maximum, as Radix's are.
      }}
      <Slider
        @value={{this.value}}
        @onValueChange={{this.setValue}}
        @max={{1000}}
        @min={{0}}
        @step={{10}}
        class="mt-2 w-full"
        role="group"
        aria-label="Price Range"
      />
    </Field>
  </template>
}
