import Component from '@glimmer/component'
import { getComponentTemplate } from '@ember/component'
import { isHTMLSafe, type SafeString } from '@ember/template'
import type { ComponentLike } from '@glint/template'
import type {
  CellContext,
  CellData,
  HeaderContext,
  RowData,
  TableFeatures,
} from '@tanstack/table-core'

/**
 * What a FlexRender reads of a cell, whatever its table's features: its column's definition and
 * its context (and, with column grouping, whether it is aggregated or a placeholder).
 */
export interface FlexCell {
  column: { columnDef: object }
  getContext(): object
  getIsAggregated?: () => boolean
  getIsPlaceholder?: () => boolean
}

/** What a FlexRender reads of a header or footer: its column's definition and its context. */
export interface FlexHeader {
  column: { columnDef: object }
  getContext(): object
}

/**
 * The arguments a component in a column's `cell` gets: the cell's context, and each of its
 * members on its own, as a React cell function destructures them (`({ row }) => …`).
 */
export interface CellComponentArgs<
  TFeatures extends TableFeatures,
  TData extends RowData,
  TValue extends CellData = CellData,
> {
  /** The whole context, as table-core's `cell.getContext()` makes it. */
  context: CellContext<TFeatures, TData, TValue>
  table: CellContext<TFeatures, TData, TValue>['table']
  column: CellContext<TFeatures, TData, TValue>['column']
  row: CellContext<TFeatures, TData, TValue>['row']
  cell: CellContext<TFeatures, TData, TValue>['cell']
  /** The cell's value. */
  getValue: CellContext<TFeatures, TData, TValue>['getValue']
  /** The cell's value, or the table's `renderFallbackValue` where it has none. */
  renderValue: CellContext<TFeatures, TData, TValue>['renderValue']
}

/** The arguments a component in a column's `header` or `footer` gets. */
export interface HeaderComponentArgs<
  TFeatures extends TableFeatures,
  TData extends RowData,
  TValue extends CellData = CellData,
> {
  /** The whole context, as table-core's `header.getContext()` makes it. */
  context: HeaderContext<TFeatures, TData, TValue>
  table: HeaderContext<TFeatures, TData, TValue>['table']
  column: HeaderContext<TFeatures, TData, TValue>['column']
  header: HeaderContext<TFeatures, TData, TValue>['header']
}

/** A component for a column's `cell`: `cell: flexComponent(StatusCell)`. */
export interface CellComponentSignature<
  TFeatures extends TableFeatures,
  TData extends RowData,
  TValue extends CellData = CellData,
> {
  Args: CellComponentArgs<TFeatures, TData, TValue>
}

/** A component for a column's `header` or `footer`: `header: flexComponent(SelectAll)`. */
export interface HeaderComponentSignature<
  TFeatures extends TableFeatures,
  TData extends RowData,
  TValue extends CellData = CellData,
> {
  Args: HeaderComponentArgs<TFeatures, TData, TValue>
}

type AnyContext = Record<string, unknown>
type Rendered = ComponentLike<{ Args: Record<string, unknown> }>

/** Whether a value is a component: one with a template, or a class (whose template it inherits). */
export function isComponent(value: unknown): value is Rendered {
  if (value === null || (typeof value !== 'object' && typeof value !== 'function')) return false
  return (
    getComponentTemplate(value as object) !== undefined ||
    (typeof value === 'function' && /^class[\s{]/.test(Function.prototype.toString.call(value)))
  )
}

/**
 * A column's `header`, `cell` or `footer` as a component: `cell: flexComponent(StatusCell)`.
 * The component gets the context and each of its members as arguments (`@row`, `@column`,
 * `@table`… see `CellComponentArgs` and `HeaderComponentArgs`). table-core's types take a
 * string or a function there, so this hands it a function that returns the component, which
 * `FlexRender` renders. It takes any context, since table-core checks a column's template
 * against the column's own value type.
 */
export function flexComponent(component: object): (context: any) => unknown {
  return () => component
}

/** What a FlexRender draws: a component with its arguments, or a value as text. */
interface Resolved {
  component?: Rendered
  args?: AnyContext
  text?: string | number | SafeString
}

/** `null`, `undefined` and booleans draw nothing, as in React; anything else draws as text. */
function drawable(value: unknown): string | number | SafeString | undefined {
  if (value === null || value === undefined || typeof value === 'boolean') return undefined
  if (typeof value === 'string' || typeof value === 'number' || isHTMLSafe(value)) {
    return value as string | number | SafeString
  }
  return String(value)
}

function resolve(template: unknown, given: object): Resolved {
  const context = given as AnyContext
  if (template === null || template === undefined) return {}
  if (isComponent(template)) return { component: template, args: context }
  if (typeof template === 'function') {
    const result: unknown = (template as (context: AnyContext) => unknown)(context)
    if (isComponent(result)) return { component: result, args: context }
    return { text: drawable(result) }
  }
  return { text: drawable(template) }
}

export interface FlexRenderSignature {
  Args: {
    /** A body cell: renders its column's `cell` (or `aggregatedCell`) with the cell's context. */
    cell?: FlexCell
    /** A header: renders its column's `header` with the header's context. */
    header?: FlexHeader
    /** A footer: renders its column's `footer` with the header's context. */
    footer?: FlexHeader
  }
}

/**
 * Renders a header, cell or footer from its column definition, as TanStack's `FlexRender`
 * does in React: give it one of `@cell`, `@header` or `@footer`. The column's template may be a
 * string, a function of the context (returning a string, a number, or a component), or a
 * component, which gets the context's members as arguments.
 *
 *   <t.Head><FlexRender @header={{header}} /></t.Head>
 *   <t.Cell><FlexRender @cell={{cell}} /></t.Cell>
 *
 * Every table `createTable()` makes carries it too, as `table.FlexRender`, as upstream's does.
 * A placeholder cell (from column grouping) renders nothing.
 */
export default class FlexRender extends Component<FlexRenderSignature> {
  get resolved(): Resolved {
    const { cell, header, footer } = this.args
    if (cell) {
      const definition = cell.column.columnDef as { cell?: unknown; aggregatedCell?: unknown }
      if (cell.getIsAggregated?.()) {
        return resolve(definition.aggregatedCell ?? definition.cell, cell.getContext())
      }
      if (cell.getIsPlaceholder?.()) return {}
      return resolve(definition.cell, cell.getContext())
    }
    if (header) {
      return resolve((header.column.columnDef as { header?: unknown }).header, header.getContext())
    }
    if (footer) {
      return resolve((footer.column.columnDef as { footer?: unknown }).footer, footer.getContext())
    }
    return {}
  }

  // The whitespace control (~) leaves nothing around what it renders, as React's does.
  <template>
    {{~#let this.resolved as |r|~}}
      {{~#if r.component~}}
        <r.component
          @context={{r.args}}
          @table={{r.args.table}}
          @column={{r.args.column}}
          @header={{r.args.header}}
          @row={{r.args.row}}
          @cell={{r.args.cell}}
          @getValue={{r.args.getValue}}
          @renderValue={{r.args.renderValue}}
        />
      {{~else~}}
        {{r.text}}
      {{~/if~}}
    {{~/let~}}
  </template>
}
