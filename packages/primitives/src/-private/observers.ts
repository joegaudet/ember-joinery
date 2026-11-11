import { buildWaiter } from '@ember/test-waiters'

const waiter = buildWaiter('@ember-joinery/primitives:observers')

/** What an observer calls back with: one entry for one element. */
export type EntryCallback<Entry> = (entry: Entry) => unknown

/** The part of IntersectionObserver and ResizeObserver this shares. */
export interface ElementObserver {
  observe(element: Element): void
  unobserve(element: Element): void
  disconnect(): void
}

/**
 * One observer shared by every element and callback that asks for it: the observer hands each
 * entry to the callbacks of the entry's element. Using one observer instead of one per element
 * is much cheaper when many elements are watched. Elements are held weakly, as the observers
 * themselves hold them, so one that is never unobserved can still be collected.
 *
 * Tests wait for an element's first entry (or two frames, for an element the observer has
 * nothing to say about yet, such as a ResizeObserver's hidden one).
 */
export class SharedObserver<Entry extends { target: Element }> {
  #callbacks = new WeakMap<Element, Set<EntryCallback<Entry>>>()
  /** Each element's last entry, for a callback that starts listening after it came. */
  #latest = new WeakMap<Element, Entry>()
  readonly #waiting = new Map<Element, unknown>()
  readonly #observer: ElementObserver

  constructor(create: (deliver: (entries: Entry[]) => void) => ElementObserver) {
    this.#observer = create(this.#deliver)
  }

  #deliver = (entries: Entry[]): void => {
    for (const entry of entries) {
      this.#settle(entry.target)
      const callbacks = this.#callbacks.get(entry.target)
      if (!callbacks) continue
      this.#latest.set(entry.target, entry)
      for (const callback of [...callbacks]) callback(entry)
    }
  }

  #wait(element: Element): void {
    this.#settle(element)
    const token = waiter.beginAsync()
    this.#waiting.set(element, token)
    requestAnimationFrame(() =>
      requestAnimationFrame(() => {
        if (this.#waiting.get(element) === token) this.#settle(element)
      }),
    )
  }

  #settle(element: Element): void {
    const token = this.#waiting.get(element)
    if (token === undefined) return
    this.#waiting.delete(element)
    waiter.endAsync(token)
  }

  /**
   * Gives `callback` alone the entry `element`'s other callbacks last had: where the element is
   * now, since the observer would have sent another had it changed. It comes after the current
   * render, as the observer's own entries do, and not at all if a newer entry reaches the
   * callback first or it stops listening.
   */
  #replay(element: Element, callback: EntryCallback<Entry>, entry: Entry): void {
    const token = waiter.beginAsync()
    queueMicrotask(() => {
      waiter.endAsync(token)
      if (this.#latest.get(element) !== entry) return
      if (this.#callbacks.get(element)?.has(callback)) callback(entry)
    })
  }

  /**
   * Starts calling `callback` with `element`'s entries, beginning with where the element is
   * now. A callback added for an element that is already observed gets the element's current
   * entry on its own: the element's other callbacks hear nothing new.
   */
  observe(element: Element, callback: EntryCallback<Entry>): void {
    const callbacks = this.#callbacks.get(element)
    if (!callbacks) {
      this.#callbacks.set(element, new Set([callback]))
      this.#wait(element)
      this.#observer.observe(element)
      return
    }
    if (callbacks.has(callback)) return
    callbacks.add(callback)
    // Before the element's first entry arrives there is nothing to replay: that entry reaches
    // every callback, this one included.
    const latest = this.#latest.get(element)
    if (latest) this.#replay(element, callback, latest)
  }

  /** Stops calling `callback` (the same function `observe` was given) for `element`. */
  unobserve(element: Element | null | undefined, callback: EntryCallback<Entry>): void {
    if (!element) return
    const callbacks = this.#callbacks.get(element)
    if (!callbacks) return
    callbacks.delete(callback)
    if (callbacks.size > 0) return
    this.#callbacks.delete(element)
    this.#latest.delete(element)
    this.#settle(element)
    this.#observer.unobserve(element)
  }

  /** Whether anything is observing `element`. */
  has(element: Element): boolean {
    return this.#callbacks.has(element)
  }

  disconnect(): void {
    for (const element of [...this.#waiting.keys()]) this.#settle(element)
    this.#callbacks = new WeakMap()
    this.#latest = new WeakMap()
    this.#observer.disconnect()
  }
}
