import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { idFor } from '@ember-joinery/primitives/id'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import type { RowData, Table, TableFeatures } from '@tanstack/table-core'
import FlexRender from './flex-render.gts'

/** What `dt.head` reads of a header, whatever its table's features. */
export interface DataTableHeader {
  isPlaceholder: boolean
  colSpan: number
  column: {
    id: string
    /** From the sorting feature: `asc`, `desc`, or `false`. */
    getIsSorted?: () => false | 'asc' | 'desc'
    /** From the sorting feature: the column's place among the sorts. */
    getSortIndex?: () => number
  }
}

/** What `dt.row` reads of a row. */
export interface DataTableRow {
  id: string
}

/** The parts' `data-test-jn-owner`: the data table around them, by the `id` it has. */
function ownedByDataTable(element: Element): void {
  const root = element.parentElement?.closest('[data-test-jn="data-table"]')
  if (root?.id) element.setAttribute('data-test-jn-owner', root.id)
}

/** What the column's sort is, as `aria-sort` says it: only the first sort, as ARIA asks. */
export function ariaSort(header: DataTableHeader): 'ascending' | 'descending' | undefined {
  if (header.isPlaceholder) return undefined
  const column = header.column
  const sorted = column.getIsSorted?.()
  if (!sorted) return undefined
  if ((column.getSortIndex?.() ?? 0) > 0) return undefined
  return sorted === 'asc' ? 'ascending' : 'descending'
}

const marker = (name: string, value?: string) => ({
  'data-test-jn-part': name,
  'data-test-jn-value': value,
})

/**
 * `<t.Head {{dt.head header}}>`: a header cell's sort, in `aria-sort` (`ascending` or
 * `descending` on the column the rows are sorted by, as the APG's sortable table has it), its
 * `colspan` over grouped columns, and the column's id for the harness.
 */
const head = part<HTMLTableCellElement, Record<string, never>, [DataTableHeader]>(
  (_, [header]) => ({
    attributes: {
      'aria-sort': ariaSort(header),
      colspan: header.colSpan > 1 ? header.colSpan : undefined,
      ...marker('head', header.column.id),
    },
    element: ownedByDataTable,
  }),
)

/** `<t.Row {{dt.row row}}>`: a body row, with its row's id, for the harness. */
const row = part<HTMLElement, Record<string, never>, [DataTableRow]>((_, [tableRow]) => ({
  attributes: marker('row', tableRow.id),
  element: ownedByDataTable,
}))

/** `<Input {{dt.filter "email"}}>`: the input that filters a column, by the column's id. */
const filter = part<HTMLElement, Record<string, never>, [string?]>((_, [columnId]) => ({
  attributes: marker('filter', columnId),
  element: ownedByDataTable,
}))

/** `<Button {{dt.previousPage}}>`: the button that goes back a page. */
const previousPage = part<HTMLElement>(() => ({
  attributes: marker('previous-page'),
  element: ownedByDataTable,
}))

/** `<Button {{dt.nextPage}}>`: the button that goes on a page. */
const nextPage = part<HTMLElement>(() => ({
  attributes: marker('next-page'),
  element: ownedByDataTable,
}))

/** `<DropdownMenu {{dt.viewOptions}}>`: the menu of columns to show and hide. */
const viewOptions = part<HTMLElement>(() => ({
  attributes: marker('view-options'),
  element: ownedByDataTable,
}))

/** What a `<DataTable>` yields: its table, `FlexRender`, and a modifier for each part. */
export interface DataTableParts<TFeatures extends TableFeatures, TData extends RowData> {
  /** The table it was given. */
  table: Table<TFeatures, TData>
  /** Renders a header, cell or footer from its column definition. */
  FlexRender: typeof FlexRender
  /** On each header cell (`<t.Head {{dt.head header}}>`): its `aria-sort` and `colspan`. */
  head: PartModifier<HTMLTableCellElement, Record<string, never>, [DataTableHeader]>
  /** On each body row (`<t.Row {{dt.row row}}>`). */
  row: PartModifier<HTMLElement, Record<string, never>, [DataTableRow]>
  /** On a column's filter input (`<Input {{dt.filter "email"}}>`). */
  filter: PartModifier<HTMLElement, Record<string, never>, [string?]>
  /** On the button that goes back a page. */
  previousPage: PartModifier<HTMLElement>
  /** On the button that goes on a page. */
  nextPage: PartModifier<HTMLElement>
  /** On the dropdown menu that shows and hides columns (`<DropdownMenu {{dt.viewOptions}}>`). */
  viewOptions: PartModifier<HTMLElement>
}

export interface DataTableSignature<TFeatures extends TableFeatures, TData extends RowData> {
  Args: {
    /** The table, from `createTable()`. */
    table: Table<TFeatures, TData>
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: {
    /** What goes around the table (a filter, the column menu, pagination) and the table. */
    default: [DataTableParts<TFeatures, TData>]
  }
  Element: HTMLElement
}

/**
 * The element around a data table and the controls that work it: upstream's
 * `<div className="w-full">`, which `DataTableHarness` scopes to. It renders nothing of its
 * own, but it yields the modifiers that mark each part for the harness, and that give the
 * header cells their `aria-sort`, which upstream's leave out:
 *
 *   <DataTable @table={{this.table}} class="w-full" as |dt|>
 *     <Input placeholder="Filter emails..." {{dt.filter "email"}} … />
 *     <Table as |t|>
 *       …<t.Head {{dt.head header}}><dt.FlexRender @header={{header}} /></t.Head>
 *       …<t.Row {{dt.row row}}>…</t.Row>
 *     </Table>
 *     <Button {{dt.previousPage}} …>Previous</Button>
 *     <Button {{dt.nextPage}} …>Next</Button>
 *   </DataTable>
 */
export default class DataTable<
  TFeatures extends TableFeatures,
  TData extends RowData,
> extends Component<DataTableSignature<TFeatures, TData>> {
  get id(): string {
    return idFor(this)
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      id={{this.id}}
      data-test-jn="data-table"
      data-test-jn-name={{@name}}
      ...attributes
    >
      {{yield
        (hash
          table=@table
          FlexRender=FlexRender
          head=head
          row=row
          filter=filter
          previousPage=previousPage
          nextPage=nextPage
          viewOptions=viewOptions
        )
      }}
    </As>
  </template>
}
