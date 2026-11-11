import { tracked } from '@glimmer/tracking'
import { buildWaiter } from '@ember/test-waiters'
import type { TableReactivityBindings } from '@tanstack/table-core/reactivity'

/** How deep `untrack()` calls are nested: inside one, atoms are read without being tracked. */
let untracking = 0

/** `settled()` waits for the work table-core puts off until after a render (its auto-resets). */
const waiter = buildWaiter('@ember-joinery/data-table:scheduled')

type Observer<T> = { next?: (value: T) => void }
type Listener<T> = Observer<T> | ((value: T) => void)
type Subscription = { unsubscribe: () => void }

const notify = <T>(listener: Listener<T>, value: T): void =>
  typeof listener === 'function' ? listener(value) : listener.next?.(value)

/**
 * A writable atom on Ember's autotracking: reading `get()` in a template or getter tracks it,
 * and `set()` re-renders what read it. Table state (`table.baseAtoms`) lives in these.
 */
class TrackedAtom<T> {
  @tracked private current: T
  /** The same value, read where nothing may track it (`untrack()`, and `set`'s updater). */
  #raw: T
  readonly #compare: (previous: T, next: T) => boolean
  readonly #listeners = new Set<Listener<T>>()

  constructor(value: T, compare: (previous: T, next: T) => boolean = Object.is) {
    this.current = value
    this.#raw = value
    this.#compare = compare
  }

  get = (): T => (untracking > 0 ? this.#raw : this.current)

  set = (updater: T | ((previous: T) => T)): void => {
    const next =
      typeof updater === 'function' ? (updater as (previous: T) => T)(this.#raw) : updater
    if (this.#compare(this.#raw, next)) return
    this.#raw = next
    this.current = next
    for (const listener of this.#listeners) notify(listener, next)
  }

  subscribe = (listener: Listener<T>): Subscription => {
    this.#listeners.add(listener)
    return { unsubscribe: () => void this.#listeners.delete(listener) }
  }
}

/**
 * A derived atom: `get()` computes it afresh each time, so whatever it reads is tracked where it
 * is read, and keeps handing back the same value while `compare` finds the new one equal (the
 * table's `store` snapshot compares shallowly), so table-core's memos see stable references.
 */
function derivedAtom<T>(compute: () => T, compare: (previous: T, next: T) => boolean = Object.is) {
  let hasValue = false
  let value: T
  return {
    get(): T {
      const next = compute()
      if (!hasValue || !compare(value, next)) {
        value = next
        hasValue = true
      }
      return value
    },
    subscribe(): Subscription {
      throw new Error(
        'Joinery data table: a derived table atom has no subscriptions in Ember. Read it (`table.store.state`, `table.atoms.<slice>.get()`) in a template or getter instead: autotracking re-renders what reads it.',
      )
    },
  }
}

/**
 * TanStack Table's reactivity bindings for Ember, which `createTable()` gives every table: its
 * state lives in tracked atoms, so a template or getter that reads the table (a row model, a
 * column's sort, `table.store.state`) re-renders when that state changes, and nothing else
 * does. Pass them yourself to table-core's `constructTable()` as `coreReactivityFeature`.
 */
export function emberReactivity(): TableReactivityBindings {
  return {
    // Options come from the function `createTable()` is given, read through a tracked cache.
    createOptionsStore: false,
    wrapExternalAtoms: false,
    addSubscription: () => {
      throw new Error('Joinery data table: external atoms are not supported in Ember')
    },
    unmount: () => {},
    batch: fn => fn(),
    untrack<T>(fn: () => T): T {
      untracking += 1
      try {
        return fn()
      } finally {
        untracking -= 1
      }
    },
    // After the render that asked for it: an auto-reset writes state the render has read.
    schedule(fn) {
      const token = waiter.beginAsync()
      queueMicrotask(() => {
        try {
          fn()
        } finally {
          waiter.endAsync(token)
        }
      })
    },
    createWritableAtom: (value, options) => new TrackedAtom(value, options?.compare) as never,
    createReadonlyAtom: (fn, options) => derivedAtom(fn, options?.compare) as never,
  }
}
