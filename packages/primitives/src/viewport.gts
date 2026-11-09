import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import { modifier } from 'ember-modifier'
import { As, type TagName } from './as.gts'
import { SharedObserver, type EntryCallback } from './-private/observers.ts'
import { service } from './service.ts'

export interface ViewportOptions {
  /**
   * A margin around the viewport, as CSS writes `margin` (`'200px'`, `'10% 0px'`): a positive
   * one counts an element as visible before it scrolls in. Default `'0px'`.
   */
  rootMargin?: string
  /**
   * How much of the element must be visible for the callback to run: `0` (the default) as soon
   * as one pixel is, `1` when all of it is, or a list (`[0, 0.5, 1]`) to hear each step.
   */
  threshold?: number | number[]
}

function keyOf(options: ViewportOptions): string {
  const threshold = [options.threshold ?? 0].flat().join(',')
  return `${options.rootMargin ?? '0px'}|${threshold}`
}

/**
 * The app's intersection observers: one `IntersectionObserver` for each set of options,
 * however many elements and callbacks use it. Get it with `viewport(this)`.
 */
export class ViewportObservers {
  readonly #observers = new Map<string, SharedObserver<IntersectionObserverEntry>>()

  constructor() {
    registerDestructor(this, () => {
      for (const observer of this.#observers.values()) observer.disconnect()
      this.#observers.clear()
    })
  }

  /**
   * Calls `callback` with an `IntersectionObserverEntry` each time `element` crosses into or
   * out of the viewport (or past a `threshold`), and once at the start with where it is now.
   * The options pick the observer; every element observed with the same options shares one.
   */
  observe(
    element: Element,
    callback: EntryCallback<IntersectionObserverEntry>,
    options: ViewportOptions = {},
  ): void {
    const key = keyOf(options)
    let observer = this.#observers.get(key)
    if (!observer) {
      observer = new SharedObserver<IntersectionObserverEntry>(
        deliver =>
          new IntersectionObserver(deliver, {
            rootMargin: options.rootMargin ?? '0px',
            threshold: options.threshold ?? 0,
          }),
      )
      this.#observers.set(key, observer)
    }
    observer.observe(element, callback)
  }

  /**
   * Stops calling `callback` for `element`. Pass the same function `observe` was given, as
   * with `removeEventListener`.
   */
  unobserve(
    element: Element | null | undefined,
    callback: EntryCallback<IntersectionObserverEntry>,
  ): void {
    for (const observer of this.#observers.values()) observer.unobserve(element, callback)
  }
}

/**
 * The app's intersection observers (one per owner, so one per test), for knowing when
 * elements scroll into view without an `IntersectionObserver` each:
 *
 *   class Row extends Component {
 *     @tracked seen = false
 *
 *     watch = modifier(element => {
 *       const observers = viewport(this)
 *       const onChange = (entry: IntersectionObserverEntry) => (this.seen = entry.isIntersecting)
 *       observers.observe(element, onChange, { rootMargin: '100px' })
 *       return () => observers.unobserve(element, onChange)
 *     })
 *   }
 *
 * It is ember-primitives' `viewport`, which shares one observer; this one also honours the
 * options, with one observer for each set of them.
 *
 * @param context anything with an owner, or the owner itself
 */
export function viewport(context: object): ViewportObservers {
  return service(context, ViewportObservers)
}

/** How `InViewport` renders its block: inside its element, or in place of it. */
export type InViewportMode = 'contain' | 'replace'

export interface InViewportSignature {
  Element: HTMLElement
  Args: {
    /**
     * `contain` (the default) renders the block inside the element once it is near the
     * viewport; `replace` renders the block in place of the element, which goes.
     */
    mode?: InViewportMode
    /** The element's tag, before and (in `contain` mode) after. Default `div`. */
    tagName?: TagName
    /**
     * How near the viewport counts, as `IntersectionObserver`'s `rootMargin`: `'200px'` renders
     * the block 200px before it would scroll in. Default `'0px'`.
     */
    rootMargin?: string
  }
  Blocks: {
    /** What renders once the element has come near the viewport, and stays from then on. */
    default: []
  }
}

/**
 * Renders its block only once it comes near the viewport, for content below the fold that
 * is expensive to render, or that measures itself on render:
 *
 *   <InViewport @rootMargin="200px" class="chart-slot">
 *     <RevenueChart />
 *   </InViewport>
 *
 * Until then it renders an empty element (a `div`, or `@tagName`), with its attributes, to be
 * watched; give it the size the content will have, so the page doesn't jump. Once the block
 * renders it stays, wherever the page scrolls. With `@mode="replace"`, the block takes the
 * element's place rather than going inside it. It is ember-primitives' `InViewport`, with
 * `@rootMargin` added.
 */
export class InViewport extends Component<InViewportSignature> {
  @tracked hasIntersected = false

  get mode(): InViewportMode {
    const mode = this.args.mode ?? 'contain'
    if (mode !== 'contain' && mode !== 'replace') {
      throw new Error(`Joinery: InViewport's @mode is "contain" or "replace", not "${mode}"`)
    }
    return mode
  }

  get isReplacing(): boolean {
    return this.mode === 'replace'
  }

  get tagName(): TagName {
    return this.args.tagName ?? 'div'
  }

  handle = (entry: IntersectionObserverEntry): void => {
    if (!entry.isIntersecting || this.hasIntersected) return
    this.hasIntersected = true
    viewport(this).unobserve(entry.target, this.handle)
  }

  observe = modifier((element: Element, _: [], { rootMargin }: { rootMargin?: string }) => {
    if (this.hasIntersected) return
    const observers = viewport(this)
    observers.observe(element, this.handle, { rootMargin })
    return () => observers.unobserve(element, this.handle)
  })

  <template>
    {{#if this.isReplacing}}
      {{#if this.hasIntersected}}
        {{yield}}
      {{else}}
        <As @as={{this.tagName}} {{this.observe rootMargin=@rootMargin}} ...attributes />
      {{/if}}
    {{else}}
      <As @as={{this.tagName}} {{this.observe rootMargin=@rootMargin}} ...attributes>
        {{#if this.hasIntersected}}
          {{yield}}
        {{/if}}
      </As>
    {{/if}}
  </template>
}
