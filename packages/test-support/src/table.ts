import { Harness } from './harness.ts'
import { NotFoundError } from './-private/tree.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** A row's cells, `th` and `td`, in order. */
function cellsOf(row: HTMLTableRowElement): HTMLTableCellElement[] {
  return [...row.cells]
}

/**
 * Drives a `<Table>` from `@ember-joinery/ember`. It reads the table as a screen reader does,
 * through its native structure: the caption, the header row's cells, and each row of the body
 * and the footer.
 *
 *   const invoices = new TableHarness('invoices') // <Table @name="invoices">
 *   assert.deepEqual(invoices.columns, ['Invoice', 'Status', 'Method', 'Amount'])
 *   assert.strictEqual(invoices.cell(0, 'Amount').textContent, '$250.00')
 *   assert.deepEqual(invoices.column('Status'), ['Paid', 'Pending', 'Unpaid'])
 */
export class TableHarness extends Harness {
  static override component = 'table'

  /** The table element itself: `element`, typed. */
  get table(): HTMLTableElement {
    return this.element as HTMLTableElement
  }

  /** The element around the table that scrolls it sideways when it is too wide (`table-container`). */
  get container(): HTMLElement {
    const container = this.element.parentElement
    if (!container || container.getAttribute('data-slot') !== 'table-container') {
      throw new NotFoundError(`no table container around ${this}`)
    }
    return container
  }

  /** The caption's text, or `null` without one. */
  get caption(): string | null {
    const caption = this.table.caption
    return caption ? text(caption) : null
  }

  /** The text of each cell in the header's last row: the columns' names. */
  get columns(): string[] {
    const rows = this.#rowsOf(this.table.tHead)
    const last = rows.at(-1)
    return last ? cellsOf(last).map(text) : []
  }

  /** The body's rows (`tr`), in order. */
  get rowElements(): HTMLTableRowElement[] {
    return [...this.table.tBodies].flatMap(body => this.#rowsOf(body))
  }

  /** The text of each body row's cells, row by row. */
  get rows(): string[][] {
    return this.rowElements.map(row => cellsOf(row).map(text))
  }

  /** How many rows the body has. */
  get rowCount(): number {
    return this.rowElements.length
  }

  /** The text of each footer row's cells, row by row (`[]` without a footer). */
  get footer(): string[][] {
    return this.#rowsOf(this.table.tFoot).map(row => cellsOf(row).map(text))
  }

  /** The body's row at `index`, counting from 0. Throws when there is none. */
  row(index: number): HTMLTableRowElement {
    const row = this.rowElements[index]
    if (!row) throw new NotFoundError(`no row ${index} in ${this} (it has ${this.rowCount})`)
    return row
  }

  /**
   * The cell of the body's row `index` in a column, given by its position or its name (a header
   * cell's text). It counts cells, so a cell spanning columns (`colspan`) counts once.
   */
  cell(index: number, column: number | string): HTMLTableCellElement {
    const position = this.#columnIndex(column)
    const cell = cellsOf(this.row(index))[position]
    if (!cell) throw new NotFoundError(`no cell ${position} in row ${index} of ${this}`)
    return cell
  }

  /** The text of every body row's cell in a column, given by its position or its name. */
  column(column: number | string): string[] {
    const position = this.#columnIndex(column)
    return this.rowElements.map(row => {
      const cell = cellsOf(row)[position]
      return cell ? text(cell) : ''
    })
  }

  #columnIndex(column: number | string): number {
    if (typeof column === 'number') return column
    const index = this.columns.indexOf(column)
    if (index === -1) throw new NotFoundError(`no column "${column}" in ${this}`)
    return index
  }

  /** A section's own rows: not a nested table's. */
  #rowsOf(section: HTMLTableSectionElement | null): HTMLTableRowElement[] {
    return section ? [...section.rows] : []
  }
}
