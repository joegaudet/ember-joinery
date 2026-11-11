import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import Autoplay from 'embla-carousel-autoplay'
import { Card } from '@ember-joinery/ember'
import { Carousel } from '@ember-joinery/carousel'

const slides = Array.from({ length: 5 }, (_, index) => index + 1)

export default class CarouselPlugin extends Component {
  // One plugin for this carousel, made once, as upstream's useRef keeps it.
  plugin = Autoplay({ delay: 2000, stopOnInteraction: true })
  plugins = [this.plugin]

  <template>
    {{! Named (aria-label), which upstream's isn't: a page with several carousels needs each named. }}
    <Carousel
      @plugins={{this.plugins}}
      class="w-full max-w-[10rem] sm:max-w-xs"
      aria-label="Numbers, playing on their own"
      {{on "mouseenter" this.plugin.stop}}
      {{on "mouseleave" this.plugin.reset}}
      as |c|
    >
      <c.Content>
        {{#each slides as |number|}}
          <c.Item>
            <div class="p-1">
              <Card as |card|>
                <card.Content class="flex aspect-square items-center justify-center p-6">
                  <span class="text-4xl font-semibold">{{number}}</span>
                </card.Content>
              </Card>
            </div>
          </c.Item>
        {{/each}}
      </c.Content>
      <c.Previous />
      <c.Next />
    </Carousel>
  </template>
}
