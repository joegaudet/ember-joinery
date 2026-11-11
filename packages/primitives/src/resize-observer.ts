import { registerDestructor } from '@ember/destroyable'
import { SharedObserver, type EntryCallback } from './-private/observers.ts'
import { service } from './service.ts'

const LOOP_MESSAGES = [
  'ResizeObserver loop limit exceeded',
  'ResizeObserver loop completed with undelivered notifications.',
]

const IGNORING = Symbol.for('@ember-joinery/primitives:ignores-resize-observer-loops')

function isLoopMessage(message: unknown): boolean {
  return typeof message === 'string' && LOOP_MESSAGES.includes(message)
}

let listening = false

/**
 * Stops the browser's "ResizeObserver loop" message from counting as an error. It isn't one:
 * the browser is saying it will deliver a resize in the next frame instead of this one. But it
 * arrives as an `error` event on `window`, which fails tests and fills error trackers.
 *
 * `resizeObserver()` calls it for you, and so does anchoring (`anchorTo`, `anchor()`), whose
 * floating element can be sized by its anchor. It wraps `window.onerror` once (again only if
 * something replaces it), and listens for the `error` event once.
 */
export function ignoreROError(): void {
  if (!listening) {
    listening = true
    window.addEventListener('error', event => {
      if (isLoopMessage(event.message)) {
        event.preventDefault()
        event.stopImmediatePropagation()
      }
    })
  }
  const previous = window.onerror as (OnErrorEventHandlerNonNull & { [IGNORING]?: true }) | null
  if (typeof previous !== 'function' || previous[IGNORING]) return
  const wrapped = Object.assign(
    function (this: unknown, ...args: Parameters<OnErrorEventHandlerNonNull>) {
      if (isLoopMessage(args[0])) return true
      return previous.apply(this, args)
    },
    { [IGNORING]: true as const },
  )
  window.onerror = wrapped
}

/**
 * The app's resize observer: one `ResizeObserver` for every element and callback. Get it with
 * `resizeObserver(this)`.
 */
export class ResizeObservers {
  readonly #observer = new SharedObserver<ResizeObserverEntry>(
    deliver => new ResizeObserver(deliver),
  )

  constructor() {
    ignoreROError()
    registerDestructor(this, () => this.#observer.disconnect())
  }

  /**
   * Calls `callback` with a `ResizeObserverEntry` each time `element` changes size, and once at
   * the start, once it has a size.
   */
  observe(element: Element, callback: EntryCallback<ResizeObserverEntry>): void {
    this.#observer.observe(element, callback)
  }

  /** Stops calling `callback` (the same function `observe` was given) for `element`. */
  unobserve(
    element: Element | null | undefined,
    callback: EntryCallback<ResizeObserverEntry>,
  ): void {
    this.#observer.unobserve(element, callback)
  }
}

/**
 * The app's resize observer (one per owner, so one per test). One `ResizeObserver` shared by
 * every element is much cheaper than one each:
 *
 *   const observer = resizeObserver(this)
 *   observer.observe(element, entry => (this.width = entry.contentRect.width))
 *
 * In a template, use `{{onResize}}` from `@ember-joinery/primitives/on-resize`. It is
 * ember-primitives' `resizeObserver`.
 *
 * @param context anything with an owner, or the owner itself
 */
export function resizeObserver(context: object): ResizeObservers {
  return service(context, ResizeObservers)
}
