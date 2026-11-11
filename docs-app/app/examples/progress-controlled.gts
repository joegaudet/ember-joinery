import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Progress, Slider } from '@ember-joinery/ember'

export default class ProgressControlled extends Component {
  @tracked value = [50]

  setValue = (value: number[]) => (this.value = value)

  get progress(): number | null {
    return this.value[0] ?? null
  }

  <template>
    <div class="flex w-full max-w-sm flex-col gap-4">
      {{! Upstream's has no name; Joinery's has one, so it passes the accessibility audit. }}
      <Progress @value={{this.progress}} aria-label="Progress" />
      <Slider
        @value={{this.value}}
        @onValueChange={{this.setValue}}
        @min={{0}}
        @max={{100}}
        @step={{1}}
      />
    </div>
  </template>
}
