import { tracked } from '@glimmer/tracking'
import { isDestroying } from '@ember/destroyable'
import type { EmblaCarouselType, EmblaOptionsType, EmblaPluginType } from 'embla-carousel'
import { getDirection } from '@ember-joinery/primitives/direction'
import { idFor } from '@ember-joinery/primitives/id'
import { defer } from '../../-private/waiter.ts'

/** Which way the slides run. */
export type CarouselOrientation = 'horizontal' | 'vertical'

/** A slide's accessible name, from its position: `(3, 5)` gives `3 of 5` by default. */
export type CarouselSlideLabel = (index: number, count: number) => string

/** What a carousel's state reads from its component's arguments, each time it needs one. */
export interface CarouselStateArgs {
  orientation: () => CarouselOrientation | undefined
  opts: () => EmblaOptionsType | undefined
  plugins: () => EmblaPluginType[] | undefined
  setApi: () => ((api: EmblaCarouselType) => void) | undefined
  slideLabel: () => CarouselSlideLabel | undefined
}

/** The labels this carousel gave its slides, so a label of the caller's own is left alone. */
const labels = new WeakMap<Element, string>()

const defaultSlideLabel: CarouselSlideLabel = (index, count) => `${index} of ${count}`

/** Keys that type into a field rather than move the carousel. */
function isEditable(target: EventTarget | null): boolean {
  if (!(target instanceof HTMLElement)) return false
  return target.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(target.tagName)
}

/**
 * A carousel's state: Embla's API once it exists, whether it can scroll either way, and the
 * actions its parts share. `<Carousel>` owns one and hands it to each part, as upstream's
 * context does.
 */
export class CarouselState {
  /** Embla's API, once the carousel's content has rendered. */
  @tracked api: EmblaCarouselType | undefined
  /** Whether there is a slide (or snap) before the current one. */
  @tracked canScrollPrev = false
  /** Whether there is a slide (or snap) after the current one. */
  @tracked canScrollNext = false

  readonly #args: CarouselStateArgs
  #scheduled = false

  constructor(args: CarouselStateArgs) {
    this.#args = args
  }

  get orientation(): CarouselOrientation {
    return this.#args.orientation() ?? 'horizontal'
  }

  /** Embla's options: the caller's `@opts`, with the axis the orientation gives, as upstream's. */
  get options(): EmblaOptionsType {
    return { ...this.#args.opts(), axis: this.orientation === 'horizontal' ? 'x' : 'y' }
  }

  get plugins(): EmblaPluginType[] {
    return this.#args.plugins() ?? []
  }

  /** The id of the content, the element holding the slides, which the buttons control. */
  get contentId(): string {
    return idFor(this, 'content')
  }

  /** Embla made the carousel: keep its state current, and hand its API to `@setApi`. */
  onInit = (api: EmblaCarouselType): void => {
    if (isDestroying(this)) return
    this.api = api
    api.on('select', this.#changed).on('reInit', this.#changed).on('slidesChanged', this.#changed)
    api.on('destroy', () =>
      defer(() => {
        if (this.api !== api || isDestroying(this)) return
        this.api = undefined
        this.canScrollPrev = this.canScrollNext = false
      }),
    )
    this.#update()
    this.#args.setApi()?.(api)
  }

  scrollPrev = (): void => {
    this.api?.scrollPrev()
  }

  scrollNext = (): void => {
    this.api?.scrollNext()
  }

  /**
   * Scrolls to a snap by index (a slide's, unless several show at once). It takes nothing
   * else, so `{{on "click" (fn c.scrollTo 2)}}` works; to jump there without the animation,
   * use the API: `c.api.scrollTo(2, true)`.
   */
  scrollTo = (index: number): void => {
    this.api?.scrollTo(index)
  }

  /**
   * The arrow keys, anywhere inside the carousel (upstream listens in the capture phase too):
   * the left arrow scrolls back and the right arrow forward, the other way round right to left;
   * a vertical carousel takes the up and down arrows as well. Keys typed into a field are left
   * to it.
   */
  onKeyDown = (event: KeyboardEvent): void => {
    if (isEditable(event.target)) return
    const rtl = getDirection(event.currentTarget as Element) === 'rtl'
    const vertical = this.orientation === 'vertical'
    let step = 0
    if (event.key === 'ArrowLeft') step = rtl ? 1 : -1
    else if (event.key === 'ArrowRight') step = rtl ? -1 : 1
    else if (vertical && event.key === 'ArrowUp') step = -1
    else if (vertical && event.key === 'ArrowDown') step = 1
    if (!step) return
    event.preventDefault()
    if (step < 0) this.scrollPrev()
    else this.scrollNext()
  }

  /**
   * An Embla event: the selection or the slides changed. It can come while the carousel
   * reinitializes during a render, so the update waits for that render to finish.
   */
  #changed = (): void => {
    if (this.#scheduled) return
    this.#scheduled = true
    defer(() => {
      this.#scheduled = false
      this.#update()
    })
  }

  #update(): void {
    const api = this.api
    if (!api || isDestroying(this)) return
    this.canScrollPrev = api.canScrollPrev()
    this.canScrollNext = api.canScrollNext()
    this.#labelSlides(api)
  }

  /**
   * Names each slide by its place (`2 of 5`), as the APG's carousel pattern asks, unless it has
   * a name of the caller's own (`aria-label` or `aria-labelledby`).
   */
  #labelSlides(api: EmblaCarouselType): void {
    const slideLabel = this.#args.slideLabel() ?? defaultSlideLabel
    const slides = api.slideNodes()
    slides.forEach((slide, index) => {
      if (slide.getAttribute('data-slot') !== 'carousel-item') return
      if (slide.hasAttribute('aria-labelledby')) return
      const current = slide.getAttribute('aria-label')
      if (current !== null && current !== labels.get(slide)) return
      const label = slideLabel(index + 1, slides.length)
      labels.set(slide, label)
      if (current !== label) slide.setAttribute('aria-label', label)
    })
  }
}
