import { tracked } from '@glimmer/tracking'
import { Machine, onExit, region, State, transition } from '@switchyard-ts/core'
import { machine } from '@switchyard-ts/ember'

export class ListPhase extends State {
  declare private readonly brand: never
  /** The list is closed and its popup gone. */
  static Closed = ListPhase.of('closed')
  /** The list is open. */
  static Open = ListPhase.of('open')
  /** The list has closed and its popup is animating out, filtered by the frozen query. */
  static Closing = ListPhase.of('closing')
}

export class QueryMode extends State {
  declare private readonly brand: never
  /** The input's text is what it was given (a single combobox's value's label): no filter yet. */
  static Browsing = QueryMode.of('browsing')
  /** The user has typed a query since the list opened. */
  static Querying = QueryMode.of('querying')
}

/**
 * A combobox list's modes, as Base UI's combobox keeps them in flags: where the popup is in
 * its life, and whether the user has typed since it opened. Its events follow the committed
 * `open` (sent after `openState.set()` took), never the request, so a controlled `@open` that
 * refuses a change leaves nothing frozen.
 */
export class ComboboxList extends Machine<{ phase: ListPhase; query: QueryMode }> {
  @region(ListPhase) declare phase: ListPhase
  @region(QueryMode) declare query: QueryMode

  /** The query frozen while the popup animates out (or once an item is chosen), or `null`. */
  @tracked frozenQuery: string | null = null

  get isQuerying(): boolean {
    return this.matches(QueryMode.Querying)
  }

  // `opened` and `closed` come from any phase: a controlled `@open` can change without them.

  /** It opened, maybe while still animating out. */
  @transition({ to: ListPhase.Open })
  opened() {}

  /** It closed: while a query was typed, the popup keeps showing what it matched. */
  @transition({ to: ListPhase.Closing })
  closed(query: string) {
    if (this.isQuerying) this.frozenQuery = query
  }

  /** The popup has gone, after any exit animation: start afresh. */
  @transition({ from: ListPhase.Closing, to: ListPhase.Closed })
  @transition({})
  unmounted() {
    this.frozenQuery = null
    this.browse()
  }

  /** The user typed a query. */
  @transition({ to: QueryMode.Querying })
  typed() {}

  /** Back to the given text, unfiltered. */
  @transition({ to: QueryMode.Browsing })
  browse() {}

  /** Freeze the query now (an item was chosen). */
  @transition({})
  freeze(query: string) {
    this.frozenQuery = query
  }

  @onExit(ListPhase.Closing)
  thaw() {
    this.frozenQuery = null
  }
}

/** A started `ComboboxList`, stopped when `owner` is destroyed. */
export function comboboxList(owner: object): ComboboxList {
  return machine(owner, new ComboboxList())
}
