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
 * is much cheaper when many elements are watched.
 *
 * Tests wait for an element's first entry (or two frames, for an element the observer has
 * nothing to say about yet, such as a ResizeObserver's hidden one).
 */
export class SharedObserver<Entry extends { target: Element }> {
  readonly #callbacks = new Map<Element, Set<EntryCallback<Entry>>>()
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
   * Starts calling `callback` with `element`'s entries. A callback added for an element that is
   * already observed gets the element's current entry too: the observer starts over for it.
   */
  observe(element: Element, callback: EntryCallback<Entry>): void {
    let callbacks = this.#callbacks.get(element)
    if (callbacks?.has(callback)) return
    if (!callbacks) this.#callbacks.set(element, (callbacks = new Set()))
    else this.#observer.unobserve(element)
    callbacks.add(callback)
    this.#wait(element)
    this.#observer.observe(element)
  }

  /** Stops calling `callback` (the same function `observe` was given) for `element`. */
  unobserve(element: Element | null | undefined, callback: EntryCallback<Entry>): void {
    if (!element) return
    const callbacks = this.#callbacks.get(element)
    if (!callbacks) return
    callbacks.delete(callback)
    if (callbacks.size > 0) return
    this.#callbacks.delete(element)
    this.#settle(element)
    this.#observer.unobserve(element)
  }

  /** Whether anything is observing `element`. */
  has(element: Element): boolean {
    return this.#callbacks.has(element)
  }

  disconnect(): void {
    for (const element of [...this.#waiting.keys()]) this.#settle(element)
    this.#callbacks.clear()
    this.#observer.disconnect()
  }
}
