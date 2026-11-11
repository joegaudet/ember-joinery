import type { TOC } from '@ember/component/template-only'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { embla } from '../../embla.ts'
import type { CarouselState } from './state.ts'

export interface CarouselContentSignature {
  Args: {
    /**
     * The tag of the element around the slides, instead of `div`. Not a list: its slides are
     * groups, which a list can't hold.
     */
    as?: TagName
    /** @internal Bound by `<Carousel>`. */
    carousel: CarouselState
  }
  Blocks: { default: [] }
  /** The element around the slides, which Embla moves: attributes and `class` go here. */
  Element: HTMLElement
}

/**
 * The slides, yielded as `c.Content`. As upstream's, it is two elements: Embla's viewport,
 * which clips (`data-slot="carousel-content"`), and inside it the row (or, vertically, the
 * column) of slides Embla moves. Your attributes and `class` go on the row, as upstream's
 * `className` does, so `-ms-2` (with `ps-2` on each slide) changes the spacing, and a
 * vertical carousel's height goes there too.
 */
export const CarouselContent: TOC<CarouselContentSignature> = <template>
  <div
    id={{@carousel.contentId}}
    class="jn-carousel-content"
    data-slot="carousel-content"
    data-test-jn-part="content"
    {{embla options=@carousel.options plugins=@carousel.plugins onInit=@carousel.onInit}}
  >
    <As
      @as={{@as}}
      @tag="div"
      class="jn-carousel-container"
      data-orientation={{@carousel.orientation}}
      data-test-jn-part="container"
      ...attributes
    >{{yield}}</As>
  </div>
</template>
