import { tracked } from '@glimmer/tracking'
import { createCache, getValue } from '@glimmer/tracking/primitives/cache'
import {
  constructTable,
  functionalUpdate,
  type RowData,
  type Table,
  type TableFeatures,
  type TableOptions,
  type TableState,
  type Updater,
} from '@tanstack/table-core'
import FlexRender from './components/flex-render.gts'
import { boundMethodsFeature } from './-private/bound-methods.ts'
import { emberReactivity } from './-private/reactivity.ts'

export { emberReactivity } from './-private/reactivity.ts'

/**
 * A TanStack table made by `createTable()`: table-core's table, whose state is tracked, with
 * `FlexRender` on it (`<this.table.FlexRender @cell={{cell}} />`, as upstream's
 * `<table.FlexRender cell={cell} />`) and its whole state as `state`.
 */
export type EmberTable<TFeatures extends TableFeatures, TData extends RowData> = Table<
  TFeatures,
  TData
> & {
  /** `FlexRender`, so a template that has the table needs no import of its own. */
  FlexRender: typeof FlexRender
  /** The table's whole state, every slice its features hold (`table.store.state`). Tracked. */
  readonly state: TableState<TFeatures>
}

/** The table options `createTable()` takes, or a function that returns them. */
export type EmberTableOptions<TFeatures extends TableFeatures, TData extends RowData> =
  TableOptions<TFeatures, TData> | (() => TableOptions<TFeatures, TData>)

interface Internals {
  _features: Record<string, { getDefaultTableOptions?: (table: unknown) => object }>
  options: Record<string, unknown>
}

/** The options `table.setOptions()` changed, kept above the ones the function gives. */
class Overrides {
  @tracked value: Record<string, unknown> = {}
}

/**
 * Makes a TanStack table that Ember tracks: shadcn's `useTable`, in Ember. Its state (sorting,
 * filters, pagination, selection, visibility…) is tracked, so a template or getter that reads
 * the table re-renders when what it read changes, and nothing else does.
 *
 *   import { createTable, tableFeatures, rowSortingFeature, createSortedRowModel, … } from
 *     '@ember-joinery/data-table'
 *
 *   const features = tableFeatures({ rowSortingFeature, sortedRowModel: createSortedRowModel() })
 *
 *   class Payments extends Component {
 *     table = createTable(() => ({ features, columns, data: this.args.payments }))
 *   }
 *
 * Give it a function, as above, and it reads the options again whenever something the function
 * read changes (`this.args.payments`, a `tableState()` value): that is how `data` and controlled
 * `state` follow your component. Give it an object for options that never change. `features`
 * is read once, when the table is made.
 *
 * Without `state`, the table keeps its own (`initialState` sets where it starts). To own a slice
 * yourself, as upstream's examples own theirs with `useState`, pass it in `state` with its
 * `on<Slice>Change`, from a `tableState()`.
 *
 * Templates can call the table's methods (`{{#each (this.table.getHeaderGroups) …}}`), and the
 * methods of its rows, cells, columns and headers too (`{{(row.getIsSelected)}}`,
 * `@onCheckedChange={{row.toggleSelected}}`): they come bound to their own object.
 */
export function createTable<TFeatures extends TableFeatures, TData extends RowData>(
  options: EmberTableOptions<TFeatures, TData>,
): EmberTable<TFeatures, TData> {
  const read = typeof options === 'function' ? options : () => options
  const initial = read()
  const features = {
    coreReactivityFeature: emberReactivity(),
    ...initial.features,
    // Last, so it sees the methods every other feature put on the prototypes.
    boundMethodsFeature,
  }

  const table = constructTable({ ...initial, features } as unknown as TableOptions<
    TFeatures,
    TData
  >) as unknown as EmberTable<TFeatures, TData> & Internals

  // What constructTable() merged under the options: each feature's defaults (the
  // `on<Slice>Change` that write the table's own state, and the like).
  const defaults: Record<string, unknown> = {}
  for (const feature of Object.values(table._features)) {
    Object.assign(defaults, feature.getDefaultTableOptions?.(table))
  }
  // As table-core's own merge does, these keep the values the table was made with.
  const fixed = {
    features: table.options['features'],
    atoms: initial.atoms,
    initialState: initial.initialState,
  }
  const overrides = new Overrides()
  const resolved = createCache((): Record<string, unknown> => ({
    ...defaults,
    ...(read() as Record<string, unknown>),
    ...overrides.value,
    ...fixed,
  }))

  Object.defineProperty(table, 'options', {
    configurable: true,
    enumerable: true,
    get: () => getValue(resolved),
    // `table.setOptions()` hands over the whole set: keep what it changed.
    set(next: Record<string, unknown>) {
      const current = getValue(resolved) ?? {}
      const changed: Record<string, unknown> = { ...overrides.value }
      for (const [key, value] of Object.entries(next)) {
        if (current[key] !== value) changed[key] = value
      }
      overrides.value = changed
    },
  })
  Object.defineProperty(table, 'state', {
    configurable: true,
    enumerable: true,
    get: () => table.store.get(),
  })
  table.FlexRender = FlexRender
  return table
}

/**
 * A slice of table state you own, tracked: upstream's `React.useState` for a table. Pass its
 * `value` in the table's `state` and its `set` as the slice's `on<Slice>Change`; `set` takes a
 * value or an updater function, as table-core hands it either.
 *
 *   sorting = tableState<SortingState>([])
 *   table = createTable(() => ({
 *     features, columns, data,
 *     onSortingChange: this.sorting.set,
 *     state: { sorting: this.sorting.value },
 *   }))
 */
export class TrackedState<T> {
  @tracked value: T

  constructor(initial: T) {
    this.value = initial
  }

  /** Sets it to a value, or to what an updater makes of the current one. */
  set = (updater: Updater<T>): void => {
    this.value = functionalUpdate(updater, this.value)
  }
}

/** A `TrackedState` that starts at `initial`. */
export function tableState<T>(initial: T): TrackedState<T> {
  return new TrackedState(initial)
}
