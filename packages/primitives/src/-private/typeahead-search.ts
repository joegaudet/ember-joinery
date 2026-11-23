import { after, Machine, State, transition, type Clock } from '@switchyard-ts/core'

export class SearchState extends State {
  declare private readonly brand: never
  /** Nothing typed. */
  static Idle = SearchState.of('idle')
  /** Keys are adding up; the search clears `timeout` after the last one. */
  static Typing = SearchState.of('typing')
}

/**
 * A typeahead search, as a chart: each key adds to `search` and (re)starts the wait in
 * `Typing`; the wait running out, or `reset()`, goes back to `Idle` and clears it.
 */
export class TypeaheadSearch extends Machine<SearchState> {
  // A plain clock, not the Ember test waiter one: `settled()` between keys must not outwait the
  // search, or a test could never type "bl".
  static override clock: Clock = {
    setTimeout: (fn, ms) => setTimeout(fn, ms),
    clearTimeout: handle => clearTimeout(handle as ReturnType<typeof setTimeout>),
  }

  readonly #timeout: number
  search = ''

  constructor(timeout: number) {
    super()
    this.#timeout = timeout
  }

  get timeout(): number {
    return this.#timeout
  }

  /** A key: add it to the search and restart the wait. */
  @transition({ to: SearchState.Typing, reenter: true })
  type(key: string) {
    this.search += key
  }

  /** Clear the search now. */
  @transition({ to: SearchState.Idle })
  reset() {
    this.search = ''
  }

  @after('timeout', { from: SearchState.Typing, to: SearchState.Idle })
  expired() {
    this.search = ''
  }
}
