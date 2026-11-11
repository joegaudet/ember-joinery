import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Slider } from '@ember-joinery/primitives/slider'

const PRICES = [0, 10, 20, 50, 100, 200]

function thumbLabel(index: number): string {
  return index === 0 ? 'Lowest price' : 'Highest price'
}

/** A price range on the primitive, unstyled but for the classes here: it snaps to the prices. */
export default class SliderHeadless extends Component {
  @tracked price = [20, 100]

  setPrice = (price: number[]) => (this.price = price)

  get label(): string {
    const [from, to] = this.price
    return `${from} to ${to} dollars`
  }

  <template>
    <div class="grid w-64 gap-3">
      <Slider
        @value={{this.price}}
        @onValueChange={{this.setPrice}}
        @step={{PRICES}}
        @getThumbLabel={{thumbLabel}}
        class="relative flex h-5 w-full touch-none items-center select-none"
        as |s|
      >
        <s.Track class="relative h-1 grow overflow-hidden rounded-full bg-muted">
          <s.Range class="absolute h-full bg-primary" />
        </s.Track>
        {{#each s.thumbs as |thumb|}}
          <s.Thumb
            @index={{thumb.index}}
            class="block size-4 rounded-full border border-primary bg-background shadow-sm focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:outline-none"
          />
        {{/each}}
      </Slider>
      <p class="text-sm text-muted-foreground">{{this.label}}</p>
      <ul class="flex justify-between text-xs text-muted-foreground" aria-hidden="true">
        {{#each PRICES as |price|}}
          <li>{{price}}</li>
        {{/each}}
      </ul>
    </div>
  </template>
}
