import { click, fillIn } from '@ember/test-helpers'
import {
  CheckboxHarness,
  DropdownMenuHarness,
  Harness,
  TableHarness,
} from '@ember-joinery/test-support'

const collapse = (value: string | null | undefined): string =>
  (value ?? '').replace(/\s+/g, ' ').trim()

/** Whether a button can be used: not `disabled`, and not `aria-disabled`. */
const usable = (element: Element | null): boolean =>
  Boolean(element) &&
  !(element as HTMLButtonElement).disabled &&
  element!.getAttribute('aria-disabled') !== 'true'

/** A column, as the harness's members take it: its id, its header's text, or its position. */
export type DataTableColumn = string | number

/** A column's sort, as its header cell's `aria-sort` says it. */
export type DataTableSort = 'ascending' | 'descending' | 'none'

/**
 * Drives a data table: the parts inside a `<DataTable>` from `@ember-joinery/data-table`, which
 * its modifiers mark. It reads the rows and columns the table shows, each column's sort (from
 * the header cell's `aria-sort`), which rows are selected (from each row's checkbox), and the
 * filter and pages, and works them as a user does: with the sort buttons in the headers, the
 * filter input, the row checkboxes, the page buttons and the column menu.
 *
 *   const payments = new DataTableHarness('payments') // <DataTable @name="payments">
 *   await payments.filter('ken')
 *   assert.deepEqual(payments.column('email'), ['ken99@example.com'])
 *   await payments.sort('email')
 *   assert.strictEqual(payments.sortOf('email'), 'ascending')
 *   await payments.toggleRow(0)
 *   assert.deepEqual(payments.selectedRows, [0])
 *   await payments.nextPage()
 *
 * A column is its id (the header cell's `data-test-jn-value`), its header's text, or its
 * position among the columns shown.
 */
export class DataTableHarness extends Harness {
  static override component = 'data-table'

  /** The table inside it. */
  get table(): TableHarness {
    return this.child(TableHarness)
  }

  // ----- Columns -------------------------------------------------------------------------------

  /** Every header cell (`dt.head`), in every header row. */
  get headElements(): HTMLTableCellElement[] {
    return this.parts<HTMLTableCellElement>('head')
  }

  /** The header cells of the columns shown: those in the header's last row. */
  get columnHeads(): HTMLTableCellElement[] {
    const rows = this.table.table.tHead?.rows
    const last = rows?.[rows.length - 1]
    return this.headElements.filter(head => head.parentElement === last)
  }

  /** The ids of the columns shown, in order. */
  get columnIds(): string[] {
    return this.columnHeads.map(head => head.getAttribute('data-test-jn-value') ?? '')
  }

  /** The text of each column's header, in order (`''` for one with no text, as a checkbox's). */
  get columns(): string[] {
    return this.columnHeads.map(head => collapse(head.textContent))
  }

  /** Whether the column is shown, by its id. */
  isColumnShown(id: string): boolean {
    return this.columnIds.includes(id)
  }

  /** The header cell of a column. Throws when the table doesn't show it. */
  head(column: DataTableColumn): HTMLTableCellElement {
    const head = this.columnHeads[this.#position(column)]
    if (!head) throw new Error(`Joinery harness: no column ${String(column)} in ${this}`)
    return head
  }

  #position(column: DataTableColumn): number {
    if (typeof column === 'number') return column
    const byId = this.columnIds.indexOf(column)
    if (byId !== -1) return byId
    const byText = this.columns.indexOf(column)
    if (byText !== -1) return byText
    throw new Error(
      `Joinery harness: no column "${column}" in ${this} (it shows ${this.columnIds.map(id => `"${id}"`).join(', ')})`,
    )
  }

  // ----- Rows ----------------------------------------------------------------------------------

  /** The body's rows (`dt.row`), as the table shows them: this page, filtered and sorted. */
  get rowElements(): HTMLTableRowElement[] {
    return this.parts<HTMLTableRowElement>('row')
  }

  /** Each row's id (table-core's `row.id`), in order. */
  get rowIds(): string[] {
    return this.values('row')
  }

  /** How many rows it shows. */
  get rowCount(): number {
    return this.rowElements.length
  }

  /** The text of each row's cells, row by row. */
  get rows(): string[][] {
    return this.rowElements.map(row => [...row.cells].map(cell => collapse(cell.textContent)))
  }

  /** Whether it shows no rows (its body shows `emptyText` instead). */
  get isEmpty(): boolean {
    return this.rowCount === 0
  }

  /** The body's text while it shows no rows (upstream's `No results.`), or `null`. */
  get emptyText(): string | null {
    if (!this.isEmpty) return null
    return collapse([...this.table.table.tBodies].map(body => body.textContent).join(' '))
  }

  /** The row at `index`, counting from 0. Throws when there is none. */
  row(index: number): HTMLTableRowElement {
    const row = this.rowElements[index]
    if (!row)
      throw new Error(`Joinery harness: no row ${index} in ${this} (it has ${this.rowCount})`)
    return row
  }

  /** The cell of row `index` in a column. */
  cell(index: number, column: DataTableColumn): HTMLTableCellElement {
    const position = this.#position(column)
    const cell = this.row(index).cells[position]
    if (!cell) throw new Error(`Joinery harness: no cell ${position} in row ${index} of ${this}`)
    return cell
  }

  /** The text of every row's cell in a column. */
  column(column: DataTableColumn): string[] {
    const position = this.#position(column)
    return this.rowElements.map(row => collapse(row.cells[position]?.textContent))
  }

  // ----- Sorting -------------------------------------------------------------------------------

  /** A column's sort, from its header cell's `aria-sort` (`none` without one). */
  sortOf(column: DataTableColumn): DataTableSort {
    const sort = this.head(column).getAttribute('aria-sort')
    return sort === 'ascending' || sort === 'descending' ? sort : 'none'
  }

  /** The column the rows are sorted by, and which way, or `null` while they aren't. */
  get sortedBy(): { column: string; direction: 'ascending' | 'descending' } | null {
    for (const [index, id] of this.columnIds.entries()) {
      const direction = this.sortOf(index)
      if (direction !== 'none') return { column: id, direction }
    }
    return null
  }

  /** The button in a column's header that sorts by it. Throws when it has none. */
  sortButton(column: DataTableColumn): HTMLButtonElement {
    const button = this.head(column).querySelector<HTMLButtonElement>('button')
    if (!button)
      throw new Error(`Joinery harness: column ${String(column)} of ${this} has no sort button`)
    return button
  }

  /** Clicks the sort button in a column's header. */
  async sort(column: DataTableColumn): Promise<void> {
    await click(this.sortButton(column))
  }

  // ----- Filtering -----------------------------------------------------------------------------

  /** The input that filters a column (`dt.filter`), or the first filter without a column. */
  filterInput(column?: string): HTMLInputElement {
    const input = this.queryPart<HTMLInputElement>('filter', column) ?? undefined
    if (!input) {
      const which = column === undefined ? 'filter' : `filter for "${column}"`
      throw new Error(`Joinery harness: no ${which} in ${this}`)
    }
    return input
  }

  /** What a filter holds. */
  filterValue(column?: string): string {
    return this.filterInput(column).value
  }

  /** Types `value` into a filter, as a user does, replacing what it held. */
  async filter(value: string, column?: string): Promise<void> {
    await fillIn(this.filterInput(column), value)
  }

  // ----- Pagination ----------------------------------------------------------------------------

  /** The button that goes back a page (`dt.previousPage`), or `null`. */
  get previousPageButton(): HTMLElement | null {
    return this.queryPart('previous-page')
  }

  /** The button that goes on a page (`dt.nextPage`), or `null`. */
  get nextPageButton(): HTMLElement | null {
    return this.queryPart('next-page')
  }

  /** Whether there is a page before this one: the previous button can be used. */
  get canPreviousPage(): boolean {
    return usable(this.previousPageButton)
  }

  /** Whether there is a page after this one: the next button can be used. */
  get canNextPage(): boolean {
    return usable(this.nextPageButton)
  }

  /** Clicks the previous page button. */
  async previousPage(): Promise<void> {
    await click(this.#button(this.previousPageButton, 'previous page'))
  }

  /** Clicks the next page button. */
  async nextPage(): Promise<void> {
    await click(this.#button(this.nextPageButton, 'next page'))
  }

  #button(button: HTMLElement | null, name: string): HTMLElement {
    if (!button) throw new Error(`Joinery harness: no ${name} button in ${this}`)
    return button
  }

  // ----- Selection -----------------------------------------------------------------------------

  /** The checkbox that selects a row, or `null` when the row has none. */
  rowCheckbox(index: number): CheckboxHarness | null {
    const checkbox = new CheckboxHarness({ within: this.row(index) })
    return checkbox.exists ? checkbox : null
  }

  /** The checkbox in a header cell that selects every row on the page, or `null`. */
  get selectAll(): CheckboxHarness | null {
    for (const head of this.headElements) {
      const checkbox = new CheckboxHarness({ within: head })
      if (checkbox.exists) return checkbox
    }
    return null
  }

  /**
   * Whether row `index` is selected: its checkbox is checked, or, in a table without them, the
   * row is marked `data-state="selected"`.
   */
  isSelected(index: number): boolean {
    const checkbox = this.rowCheckbox(index)
    if (checkbox) return checkbox.isChecked
    return this.row(index).getAttribute('data-state') === 'selected'
  }

  /** The rows selected, by index on this page. */
  get selectedRows(): number[] {
    return this.rowElements.flatMap((_, index) => (this.isSelected(index) ? [index] : []))
  }

  /** Clicks row `index`'s checkbox, which selects or deselects it. */
  async toggleRow(index: number): Promise<void> {
    const checkbox = this.rowCheckbox(index)
    if (!checkbox) throw new Error(`Joinery harness: row ${index} of ${this} has no checkbox`)
    await checkbox.toggle()
  }

  /** Clicks the header's checkbox, which selects (or deselects) every row on the page. */
  async toggleAll(): Promise<void> {
    const checkbox = this.selectAll
    if (!checkbox) throw new Error(`Joinery harness: ${this} has no select-all checkbox`)
    await checkbox.toggle()
  }

  // ----- Column visibility ---------------------------------------------------------------------

  /** The menu that shows and hides columns (`dt.viewOptions`). Throws when there is none. */
  get viewOptions(): DropdownMenuHarness {
    const root = this.queryPart('view-options')
    const menu = root && this.findAll(DropdownMenuHarness).find(each => each.element === root)
    if (!menu) throw new Error(`Joinery harness: no column menu in ${this}`)
    return menu
  }

  /** The columns the menu offers, by their items' text (it opens the menu to read them). */
  async columnOptions(): Promise<string[]> {
    await this.viewOptions.open()
    return this.viewOptions.items
  }

  /** Opens the column menu and toggles the column whose item reads `label`. */
  async toggleColumn(label: string): Promise<void> {
    const menu = this.viewOptions
    await menu.open()
    await menu.select(label)
  }
}
