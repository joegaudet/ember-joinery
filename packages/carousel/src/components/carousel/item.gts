import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import type { CarouselOrientation, CarouselState } from './state.ts'

/**
 * The attributes a slide renders: upstream's role, role description and `data-slot`, and the
 * orientation its rules key on. Its name (`2 of 5`) comes from the carousel once Embla has
 * counted the slides.
 */
export function itemAttributes(orientation: CarouselOrientation): Record<string, string> {
  return {
    role: 'group',
    'aria-roledescription': 'slide',
    'data-slot': 'carousel-item',
    'data-orientation': orientation,
    'data-test-jn-part': 'item',
  }
}

/** A slide as a modifier, for an element of your own (`<section {{c.item}}>`). */
export function itemModifier(carousel: CarouselState): PartModifier<HTMLElement> {
  return part<HTMLElement>(() => ({
    class: 'jn-carousel-item',
    attributes: itemAttributes(carousel.orientation),
  }))
}

export interface CarouselItemSignature {
  Args: {
    /**
     * The tag to render instead of `div`, one that may be a group (`section`): a
     * slide's role is `group`, so not `li`.
     */
    as?: TagName
    /** @internal Bound by `<Carousel>`. */
    carousel: CarouselState
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * A slide, yielded as `c.Item`: as wide as the carousel by default (`basis-full`); give it a
 * `basis-*` class to show several at once.
 */
export const CarouselItem: TOC<CarouselItemSignature> = <template>
  {{#let (itemAttributes @carousel.orientation) as |a|}}
    <As
      @as={{@as}}
      @tag="div"
      role={{get a "role"}}
      aria-roledescription={{get a "aria-roledescription"}}
      class="jn-carousel-item"
      data-slot={{get a "data-slot"}}
      data-orientation={{get a "data-orientation"}}
      data-test-jn-part={{get a "data-test-jn-part"}}
      ...attributes
    >{{yield}}</As>
  {{/let}}
</template>
