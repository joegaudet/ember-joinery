import type { TOC } from '@ember/component/template-only'
import type { ComponentLike } from '@glint/template'
import { onResize } from '@ember-joinery/primitives/on-resize'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  taggedPart,
  taggedPartModifier,
  type TaggedPartSignature,
  type TaggedPartSpec,
} from '../-private/tagged-part.gts'

const HEADER = {
  tag: 'thead',
  class: 'jn-table-header',
  slot: 'table-header',
  part: 'header',
} as const satisfies TaggedPartSpec
const BODY = {
  tag: 'tbody',
  class: 'jn-table-body',
  slot: 'table-body',
  part: 'body',
} as const satisfies TaggedPartSpec
const FOOTER = {
  tag: 'tfoot',
  class: 'jn-table-footer',
  slot: 'table-footer',
  part: 'footer',
} as const satisfies TaggedPartSpec
const ROW = {
  tag: 'tr',
  class: 'jn-table-row',
  slot: 'table-row',
  part: 'row',
} as const satisfies TaggedPartSpec
const HEAD = {
  tag: 'th',
  class: 'jn-table-head',
  slot: 'table-head',
  part: 'head',
} as const satisfies TaggedPartSpec
const CELL = {
  tag: 'td',
  class: 'jn-table-cell',
  slot: 'table-cell',
  part: 'cell',
} as const satisfies TaggedPartSpec
const CAPTION = {
  tag: 'caption',
  class: 'jn-table-caption',
  slot: 'table-caption',
  part: 'caption',
} as const satisfies TaggedPartSpec

/** What a table yields: its parts, each as a component and as a modifier for your own element. */
export interface TableParts {
  /** The header (`thead`): its rows' cells are `Head`s. */
  Header: ComponentLike<TaggedPartSignature<HTMLTableSectionElement>>
  /** The body (`tbody`). */
  Body: ComponentLike<TaggedPartSignature<HTMLTableSectionElement>>
  /** The footer (`tfoot`), on a muted band: totals and the like. */
  Footer: ComponentLike<TaggedPartSignature<HTMLTableSectionElement>>
  /** A row (`tr`). It shows it is selected with `data-state="selected"`. */
  Row: ComponentLike<TaggedPartSignature<HTMLTableRowElement>>
  /** A header cell (`th`). */
  Head: ComponentLike<TaggedPartSignature<HTMLTableCellElement>>
  /** A cell (`td`): `colspan` and the like go on it as attributes. */
  Cell: ComponentLike<TaggedPartSignature<HTMLTableCellElement>>
  /** The caption (`caption`), under the table, muted. */
  Caption: ComponentLike<TaggedPartSignature<HTMLTableCaptionElement>>
  /** `<thead {{t.header}}>`: makes your own element the header. */
  header: PartModifier<HTMLElement>
  /** Makes your own element the body. */
  body: PartModifier<HTMLElement>
  /** Makes your own element the footer. */
  footer: PartModifier<HTMLElement>
  /** `<tr {{t.row}}>`: makes your own element, or a component's, a row. */
  row: PartModifier<HTMLElement>
  /** Makes your own element a header cell. */
  head: PartModifier<HTMLElement>
  /** Makes your own element a cell. */
  cell: PartModifier<HTMLElement>
  /** Makes your own element the caption. */
  caption: PartModifier<HTMLElement>
}

const PARTS: TableParts = {
  Header: taggedPart<HTMLTableSectionElement>(HEADER),
  Body: taggedPart<HTMLTableSectionElement>(BODY),
  Footer: taggedPart<HTMLTableSectionElement>(FOOTER),
  Row: taggedPart<HTMLTableRowElement>(ROW),
  Head: taggedPart<HTMLTableCellElement>(HEAD),
  Cell: taggedPart<HTMLTableCellElement>(CELL),
  Caption: taggedPart<HTMLTableCaptionElement>(CAPTION),
  header: taggedPartModifier(HEADER),
  body: taggedPartModifier(BODY),
  footer: taggedPartModifier(FOOTER),
  row: taggedPartModifier(ROW),
  head: taggedPartModifier(HEAD),
  cell: taggedPartModifier(CELL),
  caption: taggedPartModifier(CAPTION),
}

/** What the Tab key reaches inside a table, so its container needn't be a stop of its own. */
const TABBABLE =
  'a[href], button:not(:disabled), input:not(:disabled, [type="hidden"]), select:not(:disabled), textarea:not(:disabled), [contenteditable], [tabindex]:not([tabindex="-1"])'

/**
 * Lets the keyboard scroll the table's container while the table is wider than it: then, unless
 * something inside can take focus (and so scroll it into view), the container joins the tab
 * order (`tabindex="0"`), and the arrow keys scroll it. That is what browsers with
 * keyboard-focusable scrollers do on their own, and what WCAG asks of a region that scrolls
 * (axe's `scrollable-region-focusable`). It runs when the container or the table changes size.
 */
function updateTabStop(container: Element | null): void {
  if (!container) return
  const scrolls = container.scrollWidth > container.clientWidth
  if (scrolls && !container.querySelector(TABBABLE)) container.setAttribute('tabindex', '0')
  else if (container.getAttribute('tabindex') === '0') container.removeAttribute('tabindex')
}

const containerResized = (entry: ResizeObserverEntry): void => updateTabStop(entry.target)
const tableResized = (entry: ResizeObserverEntry): void => updateTabStop(entry.target.parentElement)

export interface TableSignature {
  Args: {
    /** The table's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The table's parts: a `Caption`, a `Header`, a `Body` and a `Footer`, of `Row`s. */
    default: [TableParts]
  }
  /** The `<table>`; its container, which scrolls a wide table sideways, is around it. */
  Element: HTMLTableElement
}

/**
 * A responsive table: shadcn's Table. A native `<table>`, full width, inside a container that
 * scrolls it sideways when it is too wide for its place (and, while it does, lets the keyboard
 * scroll it too). Attributes go on the table.
 *
 *   <Table as |t|>
 *     <t.Caption>A list of your recent invoices.</t.Caption>
 *     <t.Header>
 *       <t.Row>
 *         <t.Head class="w-[100px]">Invoice</t.Head>
 *         <t.Head>Status</t.Head>
 *       </t.Row>
 *     </t.Header>
 *     <t.Body>
 *       <t.Row>
 *         <t.Cell class="font-medium">INV001</t.Cell>
 *         <t.Cell>Paid</t.Cell>
 *       </t.Row>
 *     </t.Body>
 *   </Table>
 */
const Table: TOC<TableSignature> = <template>
  <div data-slot="table-container" class="jn-table-container" {{onResize containerResized}}>
    <table
      data-slot="table"
      class="jn-table"
      data-test-jn="table"
      data-test-jn-name={{@name}}
      ...attributes
      {{onResize tableResized}}
    >{{yield PARTS}}</table>
  </div>
</template>

export default Table
