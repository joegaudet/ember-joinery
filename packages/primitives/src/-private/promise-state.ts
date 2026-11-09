import { tracked } from '@glimmer/tracking'
import { waitForPromise } from '@ember/test-waiters'

/** Why a load failed, and what was thrown. reactiveweb's `getPromiseState` error, as is. */
export interface LoadError {
  /** Which step failed: the function threw, or its promise rejected. */
  reason: string
  /** What was thrown, or what the promise rejected with. */
  original: unknown
}

/** The reactive state of a value that may still be on its way. */
export interface LoadState<T> {
  /** `true` until the promise settles. */
  readonly isLoading: boolean
  /** Why it failed, once it has; otherwise `null`. */
  readonly error: LoadError | null
  /** The value, once there is one. */
  readonly resolved: T | undefined
}

export const REASON_FUNCTION_EXCEPTION = 'Passed function threw an exception'
export const REASON_PROMISE_REJECTION = 'Promise rejected while waiting to resolve'

export type LoadInput<T> = T | Promise<T> | (() => T | Promise<T>)

function isThenable(value: unknown): value is PromiseLike<unknown> {
  return (
    typeof value === 'object' &&
    value !== null &&
    typeof (value as { then?: unknown }).then === 'function'
  )
}

/**
 * Tracks a value, a promise, or a function returning either: `isLoading` while a promise is
 * pending, then `resolved` or `error`. A function is called once, here; a value that isn't a
 * promise is resolved at once, so nothing renders a loading state for it. Tests wait for the
 * promise (it is registered with `@ember/test-waiters`).
 *
 * `transform` turns what the promise resolves with into the value (an import's module into its
 * default export, a class into its instance).
 */
export class PromiseState<T> implements LoadState<T> {
  @tracked isLoading = false
  @tracked error: LoadError | null = null
  @tracked resolved: T | undefined = undefined

  constructor(input: LoadInput<unknown>, transform: (value: unknown) => T = value => value as T) {
    let value: unknown
    try {
      value = typeof input === 'function' ? (input as () => unknown)() : input
    } catch (original) {
      this.error = { reason: REASON_FUNCTION_EXCEPTION, original }
      return
    }
    if (!isThenable(value)) {
      this.#settle(value, transform)
      return
    }
    this.isLoading = true
    void waitForPromise(
      Promise.resolve(value).then(
        result => {
          this.#settle(result, transform)
          this.isLoading = false
        },
        (original: unknown) => {
          this.error = { reason: REASON_PROMISE_REJECTION, original }
          this.isLoading = false
        },
      ),
    )
  }

  #settle(value: unknown, transform: (value: unknown) => T): void {
    try {
      this.resolved = transform(value)
    } catch (original) {
      this.error = { reason: REASON_FUNCTION_EXCEPTION, original }
    }
  }
}

/**
 * The default export of an `import()`ed module, or the value itself. A module namespace is the
 * only kind of object treated as a module.
 */
export function unwrapModule(value: unknown): unknown {
  if (
    typeof value === 'object' &&
    value !== null &&
    (value as { [Symbol.toStringTag]?: unknown })[Symbol.toStringTag] === 'Module' &&
    'default' in value
  ) {
    return (value as { default: unknown }).default
  }
  return value
}
