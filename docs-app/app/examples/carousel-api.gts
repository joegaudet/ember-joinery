import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Card } from '@ember-joinery/ember'
import { Carousel, type CarouselApi } from '@ember-joinery/carousel'

const slides = Array.from({ length: 5 }, (_, index) => index + 1)

export default class CarouselApiDemo extends Component {
  @tracked current = 0
  @tracked count = 0

  // Upstream keeps the API in state and subscribes in an effect; @setApi is called once, with
  // the API, after the carousel renders, so it can do both.
  setApi = (api: CarouselApi) => {
    this.count = api.scrollSnapList().length
    this.current = api.selectedScrollSnap() + 1

    api.on('select', () => {
      this.current = api.selectedScrollSnap() + 1
    })
  }

  <template>
    <div class="mx-auto max-w-[10rem] sm:max-w-xs">
      {{! Named (aria-label), which upstream's isn't: a page with several carousels needs each named. }}
      <Carousel
        @setApi={{this.setApi}}
        class="w-full max-w-xs"
        aria-label="Numbers, with a count"
        as |c|
      >
        <c.Content>
          {{#each slides as |number|}}
            <c.Item>
              <Card class="m-px" as |card|>
                <card.Content class="flex aspect-square items-center justify-center p-6">
                  <span class="text-4xl font-semibold">{{number}}</span>
                </card.Content>
              </Card>
            </c.Item>
          {{/each}}
        </c.Content>
        <c.Previous />
        <c.Next />
      </Carousel>
      <div class="py-2 text-center text-sm text-muted-foreground">
        Slide
        {{this.current}}
        of
        {{this.count}}
      </div>
    </div>
  </template>
}
