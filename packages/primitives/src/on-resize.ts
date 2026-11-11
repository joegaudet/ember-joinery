import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import Modifier, { type ArgsFor } from 'ember-modifier'
import { resizeObserver, type ResizeObservers } from './resize-observer.ts'

export interface OnResizeSignature {
  Element: Element
  Args: {
    Positional: [
      /** Called with the element's `ResizeObserverEntry`: at the start, and on each resize. */
      callback: (entry: ResizeObserverEntry) => void,
    ]
  }
}

/**
 * Calls a function each time the element changes size, with its `ResizeObserverEntry`:
 *
 *   <div {{onResize this.measure}}>…</div>
 *
 *   measure = (entry: ResizeObserverEntry) => (this.width = entry.contentRect.width)
 *
 * Every `{{onResize}}` in the app shares one `ResizeObserver` (`resizeObserver()`, from
 * `@ember-joinery/primitives/resize-observer`). It is ember-primitives' `onResize`.
 *
 * It is a class-based modifier, where Joinery's others are function-based: it needs the owner
 * to find the app's shared observer, and only a class-based modifier is given one.
 */
class OnResize extends Modifier<OnResizeSignature> {
  #element: Element | null = null
  #callback: ((entry: ResizeObserverEntry) => void) | null = null
  readonly #observers: ResizeObservers

  constructor(owner: Owner, args: ArgsFor<OnResizeSignature>) {
    super(owner, args)
    this.#observers = resizeObserver(owner)
    registerDestructor(this, () => this.#stop())
  }

  #stop(): void {
    if (this.#element && this.#callback) this.#observers.unobserve(this.#element, this.#callback)
    this.#element = null
    this.#callback = null
  }

  modify(element: Element, [callback]: [(entry: ResizeObserverEntry) => void]): void {
    if (typeof callback !== 'function') {
      throw new Error(`Joinery: {{onResize}} takes a function, not ${String(callback)}`)
    }
    if (element === this.#element && callback === this.#callback) return
    this.#stop()
    this.#element = element
    this.#callback = callback
    this.#observers.observe(element, callback)
  }
}

export const onResize = OnResize
