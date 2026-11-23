import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { isDestroyed, isDestroying, registerDestructor } from '@ember/destroyable'
import Modifier from 'ember-modifier'
import type Owner from '@ember/owner'
import type { WithBoundArgs } from '@glint/template'
import { presenceChart, PresenceState } from './-private/presence-chart.ts'

function animationName(styles: CSSStyleDeclaration | undefined): string {
  return styles?.animationName || 'none'
}

interface PresenceRefSignature {
  Element: Element
  Args: { Named: { presence: Presence } }
}

/** Tells a `Presence` which element animates, and runs after each render that changes it. */
class PresenceRef extends Modifier<PresenceRefSignature> {
  #element: Element | undefined

  override modify(element: Element, _: [], { presence }: { presence: Presence }): void {
    if (!this.#element) {
      this.#element = element
      registerDestructor(this, () => presence.release(element))
    }
    presence.observe(element)
  }
}

export interface PresenceSignature {
  Args: {
    /** Whether the content should be shown: usually the part's open state. */
    present: boolean
    /** Keep the content rendered even when it isn't present, for animating it yourself. */
    forceMount?: boolean
  }
  Blocks: {
    default: [
      presence: {
        /**
         * Put it on the element whose `data-state` drives the exit animation, so Presence
         * can wait for that animation before removing it.
         */
        ref: WithBoundArgs<typeof PresenceRef, 'presence'>
        /** `@present`: false while the content is on its way out. */
        isPresent: boolean
        /**
         * Whether the content is on its way out: `@present` is false and its exit animation
         * hasn't ended. With `@forceMount`, which keeps the content rendered, it says when to
         * hide it, as Radix's Collapsible does with `hidden`.
         */
        isExiting: boolean
      },
    ]
  }
}

/**
 * Keeps a part rendered while it animates out, as Radix's `Presence` does. The content renders
 * while `@present` is true. When it turns false, the part's `data-state` becomes `closed` and
 * Presence looks at the element given `ref`: if a new CSS animation started (the part's exit
 * animation, such as `data-[state=closed]:animate-out`), the content stays until it ends, and
 * otherwise it goes at once. Turning `@present` back on during the exit keeps it.
 *
 *   <Presence @present={{this.open.value}} as |presence|>
 *     <div {{presence.ref}} data-state={{if this.open.value "open" "closed"}}>…</div>
 *   </Presence>
 *
 * `ref` can go anywhere among the element's modifiers, before or after the part modifier that
 * sets `data-state`: Presence looks for the animation once the render is over.
 *
 * Tests wait for the exit: `settled()` resolves once the content is gone.
 */
export class Presence extends Component<PresenceSignature> {
  /**
   * Present, exiting or exited. Only read while `@present` is false, so the render that makes
   * it present again may send `enter()`.
   */
  #chart = presenceChart(this, { waitForExit: signal => this.#waitForExit(signal) })
  /** Whether an element has been given `ref`; without one there is nothing to wait for. */
  @tracked private observed = false

  // An untracked copy of the above, so it can be checked during rendering without being read:
  // Ember forbids changing tracked state that the same render has read.
  #observed = false

  #element: Element | undefined
  #styles: CSSStyleDeclaration | undefined
  #wasPresent: boolean = this.args.present
  /** The animation running when the content last became present, as Radix tracks it. */
  #previousAnimation = 'none'
  #fillTimer: ReturnType<typeof setTimeout> | undefined

  constructor(owner: Owner, args: PresenceSignature['Args']) {
    super(owner, args)
    if (!args.present) this.#chart.absent()
    registerDestructor(this, () => clearTimeout(this.#fillTimer))
  }

  get isRendered(): boolean {
    if (this.args.forceMount || this.args.present) return true
    return !this.#chart.matches(PresenceState.Exited) && this.observed
  }

  /**
   * Whether the content is leaving: not present, and not yet exited. While it is present this
   * reads only `@present`, so the render that makes it present again may send `enter()`.
   */
  get isExiting(): boolean {
    if (this.args.present) return false
    return !this.#chart.matches(PresenceState.Exited) && this.observed
  }

  /** Called by `ref` after every render that touches the element or `@present`. */
  observe(element: Element): void {
    const present = this.args.present
    if (this.#element !== element) this.#attach(element, present)

    if (present === this.#wasPresent) return
    this.#wasPresent = present
    if (present) this.#enter()
    else this.#exit()
  }

  /** Called when the element given `ref` is removed. */
  release(element: Element): void {
    if (this.#element !== element) return
    element.removeEventListener('animationstart', this.#onAnimationStart)
    this.#element = undefined
    this.#styles = undefined
    if (!isDestroying(this) && !isDestroyed(this)) this.#setObserved(false)
  }

  #setObserved(observed: boolean): void {
    if (this.#observed === observed) return
    this.#observed = observed
    this.observed = observed
  }

  #attach(element: Element, present: boolean): void {
    if (this.#element) this.#element.removeEventListener('animationstart', this.#onAnimationStart)
    this.#element = element
    this.#styles = getComputedStyle(element)
    element.addEventListener('animationstart', this.#onAnimationStart)
    if (present) this.#afterRender(() => (this.#previousAnimation = animationName(this.#styles)))
    // Safe during rendering: while it is present or force-mounted, `isRendered` hasn't read it.
    if (present || this.args.forceMount) this.#setObserved(true)
  }

  #onAnimationStart = (event: Event): void => {
    if (event.target === this.#element) this.#previousAnimation = animationName(this.#styles)
  }

  /**
   * Runs `look` once this render is over, unless `@present` is false by then. `ref` runs
   * among the element's modifiers, in template order, and the part modifier that sets
   * `data-state` (and so starts the animation) may come after it; Radix looks after the commit
   * for the same reason.
   */
  #afterRender(look: () => void): void {
    queueMicrotask(() => {
      if (this.#wasPresent && !isDestroying(this) && !isDestroyed(this)) look()
    })
  }

  #enter(): void {
    const element = this.#element as HTMLElement | undefined
    if (element?.style.animationFillMode === 'forwards') element.style.animationFillMode = ''
    // Safe during rendering: while it is present, `isRendered` hasn't read the chart.
    this.#chart.enter()
    this.#afterRender(() => (this.#previousAnimation = animationName(this.#styles)))
  }

  #exit(): void {
    // The content can't go during this render (it can't change state the render has read), and
    // the exit animation can only be seen once every modifier has run: see `#afterRender`.
    queueMicrotask(() => {
      if (this.#wasPresent || isDestroying(this) || isDestroyed(this)) return
      if (this.#chart.matches(PresenceState.Present)) this.#chart.exit()
    })
  }

  /** The chart's wait while exiting: aborted when `@present` turns back on. */
  async #waitForExit(signal: AbortSignal): Promise<void> {
    const element = this.#element as HTMLElement | undefined
    const running = this.#exitAnimations()
    if (!element || !running.length) return
    await Promise.allSettled(running.map(animation => animation.finished))
    if (signal.aborted) return
    // Hold the last frame until the content is removed, so it doesn't flash back.
    const style = element.style
    if (style) {
      style.animationFillMode = 'forwards'
      this.#fillTimer = setTimeout(() => {
        if (style.animationFillMode === 'forwards') style.animationFillMode = ''
      })
    }
  }

  /** The element's exit animations: none when it has none, the same one as before, or is hidden. */
  #exitAnimations(): Animation[] {
    const element = this.#element
    const styles = this.#styles
    const current = animationName(styles)
    if (!element || current === 'none' || styles?.display === 'none') return []
    if (current === this.#previousAnimation) return []

    const names = current.split(',').map(name => name.trim())
    return element
      .getAnimations()
      .filter(
        animation => animation instanceof CSSAnimation && names.includes(animation.animationName),
      )
  }

  <template>
    {{#if this.isRendered}}
      {{yield
        (hash ref=(modifier PresenceRef presence=this) isPresent=@present isExiting=this.isExiting)
      }}
    {{/if}}
  </template>
}
