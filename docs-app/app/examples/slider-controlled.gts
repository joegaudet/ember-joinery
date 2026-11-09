import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Label, Slider } from '@ember-joinery/ember'

export default class SliderControlled extends Component {
  @tracked value = [0.3, 0.7]

  setValue = (value: number[]) => (this.value = value)

  get shown(): string {
    return this.value.join(', ')
  }

  <template>
    <div class="mx-auto grid w-full max-w-xs gap-3">
      <div class="flex items-center justify-between gap-2">
        <Label for="slider-demo-temperature">Temperature</Label>
        <span class="text-sm text-muted-foreground">
          {{this.shown}}
        </span>
      </div>
      {{! As upstream's, the label's for names the slider's root, which isn't a control, so the
        thumbs keep their own names: Minimum and Maximum. }}
      <Slider
        id="slider-demo-temperature"
        @value={{this.value}}
        @onValueChange={{this.setValue}}
        @min={{0}}
        @max={{1}}
        @step={{0.1}}
      />
    </div>
  </template>
}
