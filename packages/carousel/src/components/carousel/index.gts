import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { associateDestroyableChild } from '@ember/destroyable'
import type Owner from '@ember/owner'
import type { WithBoundArgs } from '@glint/template'
import type { EmblaCarouselType, EmblaOptionsType, EmblaPluginType } from 'embla-carousel'
import { As, type TagName } from '@ember-joinery/primitives/as'
import type { PartModifier } from '@ember-joinery/primitives/part'
import { CarouselContent } from './content.gts'
import { CarouselItem, itemModifier } from './item.gts'
import { CarouselState, type CarouselOrientation, type CarouselSlideLabel } from './state.ts'
import { CarouselNext, CarouselPrevious, stepModifier, type CarouselStepOptions } from './step.gts'
import { t } from '@ember-joinery/primitives/i18n'
import { setOwner } from '@ember/owner'
import { messages } from '../../messages.ts'

export type { CarouselOrientation, CarouselSlideLabel, CarouselStepOptions }

/** Embla's API, as `@setApi` hands it over and `c.api` yields it: upstream's `CarouselApi`. */
export type CarouselApi = EmblaCarouselType

/** Embla's options, as `@opts` takes them: upstream's `CarouselOptions`. */
export type CarouselOptions = EmblaOptionsType

/** An Embla plugin, as `@plugins` takes them: upstream's `CarouselPlugin`. */
export type CarouselPlugin = EmblaPluginType

/** What `<Carousel>` yields: its parts, their modifiers, and its state, as upstream's `useCarousel()`. */
export interface CarouselYield {
  /** The slides: `<c.Content>…</c.Content>`, around the `c.Item`s. */
  Content: WithBoundArgs<typeof CarouselContent, 'carousel'>
  /** A slide: `<c.Item class="basis-1/3">…</c.Item>`. */
  Item: WithBoundArgs<typeof CarouselItem, 'carousel'>
  /** The previous slide's button. */
  Previous: WithBoundArgs<typeof CarouselPrevious, 'carousel'>
  /** The next slide's button. */
  Next: WithBoundArgs<typeof CarouselNext, 'carousel'>
  /** A slide, as a modifier on your own element: `<section {{c.item}}>`. */
  item: PartModifier<HTMLElement>
  /**
   * The previous slide's button, as a modifier on a button of your own, with the same classes
   * and attributes as `c.Previous`: `<button type="button" {{c.previous variant="ghost"}}>`.
   */
  previous: PartModifier<HTMLElement, CarouselStepOptions>
  /** The next slide's button, as a modifier on a button of your own. */
  next: PartModifier<HTMLElement, CarouselStepOptions>
  /** Embla's API, once the content has rendered; `undefined` until then. */
  api: CarouselApi | undefined
  /** Which way the slides run. */
  orientation: CarouselOrientation
  /** Whether there is a slide before the current one. */
  canScrollPrev: boolean
  /** Whether there is a slide after the current one. */
  canScrollNext: boolean
  /** Scrolls to the previous slide. */
  scrollPrev: () => void
  /** Scrolls to the next slide. */
  scrollNext: () => void
  /** Scrolls to a slide (a snap) by index: `{{on "click" (fn c.scrollTo 2)}}`. */
  scrollTo: (index: number) => void
}

export interface CarouselSignature {
  Args: {
    /** Which way the slides run, and so Embla's axis. Default `horizontal`. */
    orientation?: CarouselOrientation
    /**
     * Embla's options (`align`, `loop`, `startIndex`…; see embla-carousel.com/api/options).
     * Without a `direction`, the carousel takes the text direction from the nearest `dir`.
     */
    opts?: CarouselOptions
    /** Embla plugins, such as `Autoplay()` from `embla-carousel-autoplay`. */
    plugins?: CarouselPlugin[]
    /** Called with Embla's API once the carousel exists, to listen to its events or drive it. */
    setApi?: (api: CarouselApi) => void
    /**
     * Each slide's accessible name, from its place among them (from 1) and their count.
     * Default `2 of 5`. A slide with an `aria-label` or `aria-labelledby` of its own keeps it.
     */
    slideLabel?: CarouselSlideLabel
    /** The tag to render instead of `div`. */
    as?: TagName
    /** Its name, for `CarouselHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [CarouselYield] }
  Element: HTMLElement
}

/**
 * A carousel with motion and swipe built using Embla: shadcn's Carousel, on the
 * framework-agnostic `embla-carousel`.
 *
 *   <Carousel class="w-full max-w-xs" as |c|>
 *     <c.Content>
 *       <c.Item>…</c.Item>
 *       <c.Item>…</c.Item>
 *     </c.Content>
 *     <c.Previous />
 *     <c.Next />
 *   </Carousel>
 *
 * It is a region described as a carousel, its slides are groups described as slides and named
 * by their place (`2 of 5`), and the arrow keys anywhere inside it move between them (flipped
 * right to left). Give it an `aria-label` to name it.
 */
export default class Carousel extends Component<CarouselSignature> {
  state: CarouselState

  item: PartModifier<HTMLElement>
  previous: PartModifier<HTMLElement, CarouselStepOptions>
  next: PartModifier<HTMLElement, CarouselStepOptions>

  constructor(owner: Owner, args: CarouselSignature['Args']) {
    super(owner, args)
    this.state = associateDestroyableChild(
      this,
      new CarouselState({
        orientation: () => this.args.orientation,
        opts: () => this.args.opts,
        plugins: () => this.args.plugins,
        setApi: () => this.args.setApi,
        slideLabel: () => this.args.slideLabel,
      }),
    )
    // The state names the slides itself, in the words of the app's translator.
    setOwner(this.state, owner)
    this.item = itemModifier(this.state)
    this.previous = stepModifier(this.state, 'previous')
    this.next = stepModifier(this.state, 'next')
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      role="region"
      aria-roledescription={{t messages.carousel}}
      class="jn-carousel"
      data-slot="carousel"
      data-orientation={{this.state.orientation}}
      data-test-jn="carousel"
      data-test-jn-name={{@name}}
      ...attributes
      {{on "keydown" this.state.onKeyDown capture=true}}
    >
      {{yield
        (hash
          Content=(component CarouselContent carousel=this.state)
          Item=(component CarouselItem carousel=this.state)
          Previous=(component CarouselPrevious carousel=this.state)
          Next=(component CarouselNext carousel=this.state)
          item=this.item
          previous=this.previous
          next=this.next
          api=this.state.api
          orientation=this.state.orientation
          canScrollPrev=this.state.canScrollPrev
          canScrollNext=this.state.canScrollNext
          scrollPrev=this.state.scrollPrev
          scrollNext=this.state.scrollNext
          scrollTo=this.state.scrollTo
        )
      }}
    </As>
  </template>
}
