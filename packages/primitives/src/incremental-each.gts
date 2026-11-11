import Component from '@glimmer/component'
import { cached, tracked } from '@glimmer/tracking'
import { assert } from '@ember/debug'
import { isDestroyed, isDestroying, registerDestructor } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'
import type Owner from '@ember/owner'

const DEFAULT_BATCH_SIZE = 50

const waiter = buildWaiter('@ember-joinery/primitives:incremental-each')

type Idle = (callback: () => void) => () => void

/**
 * Runs `callback` when the browser is next idle (within 10ms), and returns how to cancel it.
 * Safari has no `requestIdleCallback`, so there each batch waits for a task of its own: still
 * one batch at a time, without the idle hint.
 */
const whenIdle: Idle =
  typeof requestIdleCallback === 'function'
    ? callback => {
        const handle = requestIdleCallback(callback, { timeout: 10 })
        return () => cancelIdleCallback(handle)
      }
    : callback => {
        const handle = setTimeout(callback, 0)
        return () => clearTimeout(handle)
      }

/** How many batches have rendered, and of which collection. */
interface Progress<T> {
  items: readonly T[] | undefined
  batches: number
}

/** One batch of items, each with its index in the whole collection. */
interface Batch<T> {
  index: number
  entries: { value: T; index: number }[]
}

export interface IncrementalEachSignature<T = unknown> {
  Args: {
    /** The items to render. A new array (not a change to this one) starts again from the first batch. */
    items: readonly T[]
    /**
     * How many items each batch adds. Larger batches finish sooner; smaller ones give the
     * browser back more often. Default 50; it must be more than 0.
     */
    batchSize?: number
    /**
     * When the first batch renders: `sync` (the default), in the same render as the component
     * (or the new `@items`), so the first paint has content; or `lazy`, a batch later like the
     * rest, so the first paint is empty, for a first batch too slow to hold the paint up for.
     */
    initial?: 'sync' | 'lazy'
    /**
     * Called, with no arguments, once every item has rendered: after the last batch, not the
     * ones before. It is called again for each new `@items`, and never for an empty one.
     */
    onDone?: () => void
  }
  Blocks: {
    /** Each item, with its index in `@items`, as `{{#each}}` yields them. */
    default: [item: T, index: number]
  }
}

/**
 * `{{#each}}` for a long list, as ember-primitives' `IncrementalEach`: it renders the items a
 * batch at a time, one batch each time the browser is idle, so the page stays responsive
 * (clicks, scrolling, hovering) while the rest of the list fills in. Every item ends up in the
 * document, so find in page, links to an item, screen readers, printing and search engines
 * see the whole list.
 *
 *   <ul>
 *     <IncrementalEach @items={{this.rows}} @batchSize={{100}} as |row index|>
 *       <li>{{index}}: {{row.label}}</li>
 *     </IncrementalEach>
 *   </ul>
 *
 * It renders no element of its own. For a scrolling box with rows of a known height, a virtual
 * list keeps less in the document. Don't nest one inside another: each level waits for its
 * own batches, so the inner rows fill in late; make only the outer loop incremental.
 *
 * While batches are pending it holds a test waiter, so `await render()` and `await settled()`
 * wait for the whole list.
 */
export class IncrementalEach<T = unknown> extends Component<IncrementalEachSignature<T>> {
  @tracked progress: Progress<T> = { items: undefined, batches: 0 }

  #cancel: (() => void) | undefined
  /** The step the pending callback renders: the collection and how many batches are in. */
  #pending: { items: readonly T[]; rendered: number } | undefined
  #token: unknown
  /** The collection the last render showed, and the last one `@onDone` was called for. */
  #seen: readonly T[] | undefined
  #doneFor: readonly T[] | undefined

  constructor(owner: Owner, args: IncrementalEachSignature<T>['Args']) {
    super(owner, args)
    registerDestructor(this, () => {
      this.#cancel?.()
      this.#endWaiter()
    })
  }

  get items(): readonly T[] {
    const { items } = this.args
    assert('<IncrementalEach> needs @items, an array', Array.isArray(items))
    return items
  }

  get batchSize(): number {
    const size = this.args.batchSize ?? DEFAULT_BATCH_SIZE
    assert(`<IncrementalEach> @batchSize must be more than 0, not ${size}`, size > 0)
    return size
  }

  get initial(): 'sync' | 'lazy' {
    const initial = this.args.initial ?? 'sync'
    assert(
      `<IncrementalEach> @initial must be "sync" or "lazy", not "${initial}"`,
      initial === 'sync' || initial === 'lazy',
    )
    return initial
  }

  /** The items in batches. A change to an item doesn't make new batches, so only that item re-renders. */
  @cached
  get batches(): Batch<T>[] {
    const items = this.items
    const size = this.batchSize
    const batches: Batch<T>[] = []
    for (let start = 0; start < items.length; start += size) {
      batches.push({
        index: batches.length,
        entries: items.slice(start, start + size).map((value, i) => ({ value, index: start + i })),
      })
    }
    return batches
  }

  /** How many batches are in the document: a new collection starts with none or one. */
  get rendered(): number {
    const { items, batches } = this.progress
    const added = items === this.items ? batches : 0
    return Math.min((this.initial === 'sync' ? 1 : 0) + added, this.batches.length)
  }

  isRendered = (batch: Batch<T>): boolean => batch.index < this.rendered

  /**
   * Called as the template renders, and again each time a batch goes in: it asks for the next
   * batch, or, once every batch is in, reports that the list is done.
   */
  next = (): void => {
    const items = this.items
    const rendered = this.rendered
    const total = this.batches.length
    // A new collection (even one shown before) gets its own `@onDone`.
    if (items !== this.#seen) {
      this.#seen = items
      this.#doneFor = undefined
    }

    if (rendered >= total) {
      this.#cancel?.()
      this.#cancel = this.#pending = undefined
      if (total === 0) return this.#endWaiter()
      if (this.#doneFor === items) return
      this.#doneFor = items
      // Once this render is over, so the last batch is in the document.
      queueMicrotask(() => {
        if (isDestroying(this) || isDestroyed(this)) return
        if (this.#doneFor !== items) return
        this.args.onDone?.()
        this.#endWaiter()
      })
      return
    }

    if (this.#pending?.items === items && this.#pending.rendered === rendered) return
    this.#cancel?.()
    this.#token ??= waiter.beginAsync()
    this.#pending = { items, rendered }
    this.#cancel = whenIdle(() => {
      this.#cancel = this.#pending = undefined
      if (isDestroying(this) || isDestroyed(this) || this.args.items !== items) return
      const { progress } = this
      this.progress = { items, batches: (progress.items === items ? progress.batches : 0) + 1 }
    })
  }

  #endWaiter(): void {
    if (this.#token === undefined) return
    waiter.endAsync(this.#token)
    this.#token = undefined
  }

  <template>
    {{~(this.next)~}}
    {{~#each this.batches as |batch|~}}
      {{~#if (this.isRendered batch)~}}
        {{~#each batch.entries as |entry|~}}
          {{yield entry.value entry.index}}
        {{~/each~}}
      {{~/if~}}
    {{~/each~}}
  </template>
}
