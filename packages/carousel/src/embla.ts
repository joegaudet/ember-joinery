import Modifier, { type ArgsFor, type NamedArgs } from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import EmblaCarousel, {
  type EmblaCarouselType,
  type EmblaOptionsType,
  type EmblaPluginType,
} from 'embla-carousel'
import { areOptionsEqual, arePluginsEqual } from 'embla-carousel-reactive-utils'
import { getDirection } from '@ember-joinery/primitives/direction'
import { watchDirection } from './-private/direction.ts'
import { defer, track, untrack } from './-private/waiter.ts'

/** What `{{embla}}` takes. */
export interface EmblaOptions {
  /**
   * Embla's options (`align`, `loop`, `axis`…; see embla-carousel.com/api/options). Without a
   * `direction`, the carousel takes the text direction at its element, from the nearest `dir`,
   * and follows it when it changes.
   */
  options?: EmblaOptionsType
  /** Embla plugins, such as `embla-carousel-autoplay`'s `Autoplay()`. */
  plugins?: EmblaPluginType[]
  /**
   * Called with the carousel's API once it exists, after the render that made it, so it may
   * set tracked state.
   */
  onInit?: (api: EmblaCarouselType) => void
}

export interface EmblaSignature {
  Element: HTMLElement
  Args: { Named: EmblaOptions }
}

/**
 * Makes an element an Embla carousel's viewport, the way `embla-carousel-react`'s
 * `useEmblaCarousel` does: the element clips, its first child is the track Embla moves, and
 * that child's children are the slides. It is the headless part of `<Carousel>`, for a
 * carousel with markup of your own:
 *
 *   <div class="overflow-hidden" {{embla options=(hash loop=true) onInit=this.setApi}}>
 *     <div class="flex">
 *       {{#each this.slides as |slide|}}<div class="min-w-0 shrink-0 basis-full">…</div>{{/each}}
 *     </div>
 *   </div>
 *
 * When `options` or `plugins` change to something different, the carousel reinitializes and
 * keeps its place (`api.reInit`), as the React hook does; it goes when the element does. While
 * it moves to a slide, or is dragged, `settled()` waits for it in tests.
 */
class EmblaModifier extends Modifier<EmblaSignature> {
  #api: EmblaCarouselType | undefined
  #element: HTMLElement | undefined
  #options: EmblaOptionsType = {}
  #plugins: EmblaPluginType[] = []
  /** The options Embla has now: the caller's, with the direction filled in. */
  #resolved: EmblaOptionsType = {}
  #unwatch: (() => void) | undefined
  #destroyed = false

  constructor(owner: Owner, args: ArgsFor<EmblaSignature>) {
    super(owner, args)
    registerDestructor(this, () => {
      this.#destroyed = true
      this.#unwatch?.()
      const api = this.#api
      if (!api) return
      untrack(api)
      api.destroy()
    })
  }

  modify(element: HTMLElement, _positional: [], named: NamedArgs<EmblaSignature>): void {
    const { options = {}, plugins = [], onInit } = named
    this.#element = element
    this.#options = options
    if (!this.#api) {
      this.#plugins = plugins
      this.#resolved = this.#resolve()
      const api = EmblaCarousel(element, this.#resolved, plugins)
      this.#api = api
      track(api)
      this.#unwatch = watchDirection(() => this.#update(this.#plugins))
      if (onInit) defer(() => !this.#destroyed && onInit(api))
      return
    }
    this.#update(plugins)
  }

  /** The caller's options, with the text direction at the element when they don't give one. */
  #resolve(): EmblaOptionsType {
    const options = this.#options
    if (options.direction) return options
    return { ...options, direction: getDirection(this.#element) }
  }

  /** Reinitializes the carousel if its options (its direction included) or plugins changed. */
  #update(plugins: EmblaPluginType[]): void {
    const api = this.#api
    if (!api || this.#destroyed) return
    const resolved = this.#resolve()
    if (areOptionsEqual(this.#resolved, resolved) && arePluginsEqual(this.#plugins, plugins)) return
    this.#resolved = resolved
    this.#plugins = plugins
    api.reInit(resolved, plugins)
  }
}

/** The `{{embla}}` modifier: see `EmblaModifier`. */
export { EmblaModifier as embla }
