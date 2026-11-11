import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Rating } from '@ember-joinery/ember'

export default class RatingDemo extends Component {
  @tracked value = 3.5

  rate = (value: number) => (this.value = value)

  <template>
    {{! Joinery's own: shadcn/ui has no Rating. Half ratings, as ember-primitives' demo shows. }}
    <div class="flex flex-col items-center gap-3">
      <Rating @value={{this.value}} @onValueChange={{this.rate}} @step={{0.5}}>
        <:label>Rate this recipe</:label>
      </Rating>
      <p class="text-sm text-muted-foreground tabular-nums">
        {{this.value}}
        out of 5
      </p>
    </div>
  </template>
}
