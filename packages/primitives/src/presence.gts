import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { isDestroyed, isDestroying, registerDestructor } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'
import Modifier from 'ember-modifier'
import type Owner from '@ember/owner'
import type { WithBoundArgs } from '@glint/template'

const waiter = buildWaiter('@ember-joinery/primitives:presence')

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
   * Whether the content has finished leaving. Only read while `@present` is false. The
   * constructor sets its starting value: a tracked field's initializer runs on first read,
   * which is too late to see the starting `@present`.
   */
  @tracked private exited = false
  /** Whether an element has been given `ref`; without one there is nothing to wait for. */
  @tracked private observed = false

  // Untracked copies of the two above, so they can be checked during rendering without being
  // read: Ember forbids changing tracked state that the same render has read.
  #exited = false
  #observed = false

  #element: Element | undefined
  #styles: CSSStyleDeclaration | undefined
  #wasPresent: boolean = this.args.present
  /** The animation running when the content last became present, as Radix tracks it. */
  #previousAnimation = 'none'
  /** Bumped on every change of `@present`, so a stale exit never removes reopened content. */
  #generation = 0
  #token: unknown
  #fillTimer: ReturnType<typeof setTimeout> | undefined

  constructor(owner: Owner, args: PresenceSignature['Args']) {
    super(owner, args)
    this.#setExited(!args.present)
    registerDestructor(this, () => {
      this.#endWait()
      clearTimeout(this.#fillTimer)
    })
  }

  get isRendered(): boolean {
    if (this.args.forceMount || this.args.present) return true
    return !this.exited && this.observed
  }

  /**
   * Whether the content is leaving: not present, and not yet exited. While it is present this
   * reads only `@present`, so the render that makes it present again may reset `exited`.
   */
  get isExiting(): boolean {
    if (this.args.present) return false
    return !this.exited && this.observed
  }

  /** Called by `ref` after every render that touches the element or `@present`. */
  observe(element: Element): void {
    const present = this.args.present
    if (this.#element !== element) this.#attach(element, present)

    if (present === this.#wasPresent) return
    this.#wasPresent = present
    this.#generation += 1
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

  #setExited(exited: boolean): void {
    if (this.#exited === exited) return
    this.#exited = exited
    this.exited = exited
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
   * Runs `look` once this render is over, unless `@present` has changed again since. `ref` runs
   * among the element's modifiers, in template order, and the part modifier that sets
   * `data-state` (and so starts the animation) may come after it; Radix looks after the commit
   * for the same reason.
   */
  #afterRender(look: () => void): void {
    const generation = this.#generation
    queueMicrotask(() => {
      if (generation === this.#generation && !isDestroying(this) && !isDestroyed(this)) look()
    })
  }

  #enter(): void {
    this.#endWait()
    const element = this.#element as HTMLElement | undefined
    if (element?.style.animationFillMode === 'forwards') element.style.animationFillMode = ''
    // Safe during rendering: while it is present, `isRendered` hasn't read it.
    this.#setExited(false)
    this.#afterRender(() => (this.#previousAnimation = animationName(this.#styles)))
  }

  #exit(): void {
    const generation = this.#generation
    const token = this.#beginWait()
    // The content can't go during this render (it can't change state the render has read), and
    // the exit animation can only be seen once every modifier has run: see `#afterRender`.
    queueMicrotask(() => {
      if (generation !== this.#generation) return this.#endWait(token)
      const element = this.#element as HTMLElement | undefined
      const running = this.#exitAnimations()
      if (!element || !running.length) return this.#settle(generation, token)

      void Promise.allSettled(running.map(animation => animation.finished)).then(() => {
        if (generation !== this.#generation) return this.#endWait(token)
        // Hold the last frame until the content is removed, so it doesn't flash back.
        const style = element.style
        if (style) {
          style.animationFillMode = 'forwards'
          this.#fillTimer = setTimeout(() => {
            if (style.animationFillMode === 'forwards') style.animationFillMode = ''
          })
        }
        this.#settle(generation, token)
      })
    })
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

  #settle(generation: number, token: unknown): void {
    this.#endWait(token)
    if (generation !== this.#generation || isDestroying(this) || isDestroyed(this)) return
    if (!this.args.present) this.#setExited(true)
  }

  /** Holds tests' `settled()` until the content is gone; a newer wait replaces an older one. */
  #beginWait(): unknown {
    this.#endWait()
    return (this.#token = waiter.beginAsync())
  }

  /** Ends the current wait, or the given one if it is still current. */
  #endWait(token: unknown = this.#token): void {
    if (token === undefined || token !== this.#token) return
    waiter.endAsync(token)
    this.#token = undefined
  }

  <template>
    {{#if this.isRendered}}
      {{yield
        (hash ref=(modifier PresenceRef presence=this) isPresent=@present isExiting=this.isExiting)
      }}
    {{/if}}
  </template>
}
