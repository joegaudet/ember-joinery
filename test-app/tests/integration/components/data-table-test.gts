import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, rerender, settled } from '@ember/test-helpers'
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import type Owner from '@ember/owner'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ArrowUpDown } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import type { CheckedState } from '@ember-joinery/primitives/checkbox'
import { Button, Checkbox, DropdownMenu, Icon, Input, Table } from '@ember-joinery/ember'
import { ButtonHarness, TableHarness, pressKey, tab, tabOrder } from '@ember-joinery/test-support'
import {
  DataTable,
  FlexRender,
  columnFilteringFeature,
  columnVisibilityFeature,
  createColumnHelper,
  createFilteredRowModel,
  createPaginatedRowModel,
  createSortedRowModel,
  createTable,
  filterFn_includesString,
  flexComponent,
  rowPaginationFeature,
  rowSelectionFeature,
  rowSortingFeature,
  sortFn_alphanumeric,
  sortFn_text,
  tableFeatures,
  constructTable,
  emberReactivity,
  tableState,
  type CellComponentSignature,
  type Column,
  type ColumnFiltersState,
  type EmberTable,
  type HeaderComponentSignature,
  type Row,
  type SortingState,
  type Table as TanStackTable,
  type TableState,
} from '@ember-joinery/data-table'
import { DataTableHarness } from '@ember-joinery/data-table/test-support'

interface Payment {
  id: string
  amount: number
  status: 'pending' | 'processing' | 'success' | 'failed'
  email: string
}

/** Upstream's five payments. */
const FIVE: Payment[] = [
  { id: 'm5gr84i9', amount: 316, status: 'success', email: 'ken99@example.com' },
  { id: '3u1reuv4', amount: 242, status: 'success', email: 'Abe45@example.com' },
  { id: 'derv1ws0', amount: 837, status: 'processing', email: 'Monserrat44@example.com' },
  { id: '5kma53ae', amount: 874, status: 'success', email: 'Silas22@example.com' },
  { id: 'bhqecj4p', amount: 721, status: 'failed', email: 'carmella@example.com' },
]

/** Twelve, for two pages of ten. */
const TWELVE: Payment[] = Array.from({ length: 12 }, (_, index) => ({
  id: `p${index + 1}`,
  amount: (index + 1) * 10,
  status: index % 2 ? 'pending' : 'success',
  email: `user${String(index + 1).padStart(2, '0')}@example.com`,
}))

const features = tableFeatures({
  columnFilteringFeature,
  columnVisibilityFeature,
  rowPaginationFeature,
  rowSelectionFeature,
  rowSortingFeature,
  filteredRowModel: createFilteredRowModel(),
  paginatedRowModel: createPaginatedRowModel(),
  sortedRowModel: createSortedRowModel(),
  filterFns: { includesString: filterFn_includesString },
  sortFns: { alphanumeric: sortFn_alphanumeric, text: sortFn_text },
})
type Features = typeof features
type PaymentsTable = TanStackTable<Features, Payment>

const columnHelper = createColumnHelper<Features, Payment>()

const pageSelection = (table: PaymentsTable): CheckedState =>
  table.getIsAllPageRowsSelected() || (table.getIsSomePageRowsSelected() && 'indeterminate')
const toggleAllPageRows = (table: PaymentsTable, value: CheckedState) =>
  table.toggleAllPageRowsSelected(!!value)
const toggleRow = (row: Row<Features, Payment>, value: CheckedState) => row.toggleSelected(!!value)
const toggleSort = (column: Column<Features, Payment>) =>
  column.toggleSorting(column.getIsSorted() === 'asc')
const dollars = (value: unknown) =>
  new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(Number(value))
const not = (value: boolean) => !value

const SelectAll: TOC<HeaderComponentSignature<Features, Payment>> = <template>
  <Checkbox
    @checked={{pageSelection @table}}
    @onCheckedChange={{fn toggleAllPageRows @table}}
    aria-label="Select all"
  />
</template>

const SelectRow: TOC<CellComponentSignature<Features, Payment>> = <template>
  <Checkbox
    @checked={{(@row.getIsSelected)}}
    @onCheckedChange={{fn toggleRow @row}}
    aria-label="Select row"
  />
</template>

const EmailHeader: TOC<HeaderComponentSignature<Features, Payment>> = <template>
  <Button @variant="ghost" {{on "click" (fn toggleSort @column)}}>
    Email
    <Icon @icon={{ArrowUpDown}} />
  </Button>
</template>

const AmountHeader = <template>
  <div class="text-right">Amount</div>
</template>

const AmountCell: TOC<CellComponentSignature<Features, Payment>> = <template>
  <div class="text-right font-medium">{{dollars (@getValue)}}</div>
</template>

const columns = columnHelper.columns([
  columnHelper.display({
    id: 'select',
    header: flexComponent(SelectAll),
    cell: flexComponent(SelectRow),
    enableSorting: false,
    enableHiding: false,
  }),
  columnHelper.accessor('status', {
    header: 'Status',
    cell: ({ row }) => row.getValue('status'),
  }),
  columnHelper.accessor('email', {
    header: flexComponent(EmailHeader),
    cell: ({ row }) => String(row.getValue('email')).toLowerCase(),
  }),
  columnHelper.accessor('amount', {
    header: flexComponent(AmountHeader),
    cell: flexComponent(AmountCell),
  }),
])

/** The state a test changes from outside. */
class State {
  @tracked data: Payment[] = FIVE
  table?: EmberTable<Features, Payment>
}

interface PaymentsSignature {
  Args: {
    state: State
    /** Own the sorting and the filters in `tableState()`s, as upstream's demo does. */
    controlled?: boolean
    initialState?: Partial<TableState<Features>>
  }
}

/** Upstream's demo, laid out with Joinery's components and the data table's parts. */
class Payments extends Component<PaymentsSignature> {
  sorting = tableState<SortingState>([])
  columnFilters = tableState<ColumnFiltersState>([])

  table = createTable(() => ({
    features,
    data: this.args.state.data,
    columns,
    initialState: this.args.initialState,
    ...(this.args.controlled && {
      onSortingChange: this.sorting.set,
      onColumnFiltersChange: this.columnFilters.set,
      state: { sorting: this.sorting.value, columnFilters: this.columnFilters.value },
    }),
  }))

  constructor(owner: Owner, args: PaymentsSignature['Args']) {
    super(owner, args)
    args.state.table = this.table
  }

  get emailFilter(): string {
    return (this.table.getColumn('email')?.getFilterValue() as string) ?? ''
  }

  filterEmails = (value: string) => this.table.getColumn('email')?.setFilterValue(value)

  get hideableColumns() {
    return this.table.getAllColumns().filter(column => column.getCanHide())
  }

  <template>
    <DataTable @table={{this.table}} @name="payments" class="w-full" as |dt|>
      <div class="flex items-center py-4">
        <Input
          placeholder="Filter emails..."
          @value={{this.emailFilter}}
          @onValueChange={{this.filterEmails}}
          {{dt.filter "email"}}
        />
        <DropdownMenu {{dt.viewOptions}} as |m|>
          <Button @variant="outline" {{m.trigger}}>Columns</Button>
          <m.Content @align="end">
            <m.Group>
              {{#each this.hideableColumns as |column|}}
                <m.CheckboxItem
                  @checked={{(column.getIsVisible)}}
                  @onCheckedChange={{column.toggleVisibility}}
                >{{column.id}}</m.CheckboxItem>
              {{/each}}
            </m.Group>
          </m.Content>
        </DropdownMenu>
      </div>
      <Table as |t|>
        <t.Header>
          {{#each (this.table.getHeaderGroups) key="id" as |headerGroup|}}
            <t.Row>
              {{#each headerGroup.headers key="id" as |header|}}
                <t.Head {{dt.head header}}>
                  {{#unless header.isPlaceholder}}
                    <this.table.FlexRender @header={{header}} />
                  {{/unless}}
                </t.Head>
              {{/each}}
            </t.Row>
          {{/each}}
        </t.Header>
        <t.Body>
          {{#let (this.table.getRowModel) as |model|}}
            {{#each model.rows key="id" as |row|}}
              <t.Row data-state={{if (row.getIsSelected) "selected"}} {{dt.row row}}>
                {{#each (row.getVisibleCells) key="id" as |cell|}}
                  <t.Cell><dt.FlexRender @cell={{cell}} /></t.Cell>
                {{/each}}
              </t.Row>
            {{else}}
              <t.Row>
                <t.Cell colspan={{columns.length}}>No results.</t.Cell>
              </t.Row>
            {{/each}}
          {{/let}}
        </t.Body>
      </Table>
      <div>
        {{#let
          (this.table.getFilteredSelectedRowModel) (this.table.getFilteredRowModel)
          as |selected filtered|
        }}
          <p data-case="count">{{selected.rows.length}}
            of
            {{filtered.rows.length}}
            row(s) selected.</p>
        {{/let}}
        <Button
          @name="previous"
          disabled={{not (this.table.getCanPreviousPage)}}
          {{on "click" this.table.previousPage}}
          {{dt.previousPage}}
        >Previous</Button>
        <Button
          @name="next"
          disabled={{not (this.table.getCanNextPage)}}
          {{on "click" this.table.nextPage}}
          {{dt.nextPage}}
        >Next</Button>
      </div>
    </DataTable>
  </template>
}

const countText = () =>
  (document.querySelector('[data-case="count"]')?.textContent ?? '').replace(/\s+/g, ' ').trim()

module('Integration | components | data-table', function (hooks) {
  setupRenderingTest(hooks)

  test('createTable renders each header and cell from its column definition', async function (assert) {
    const coreOnly = tableFeatures({})
    const helper = createColumnHelper<typeof coreOnly, Payment>()
    const eq = (a: unknown, b: unknown) => a === b
    const CellArgs: TOC<CellComponentSignature<typeof coreOnly, Payment, string>> = <template>
      <span
        data-case="args"
        data-row={{@row.id}}
        data-column={{@column.id}}
        data-cell={{@cell.id}}
        data-value={{(@getValue)}}
        data-same-table={{if (eq @table @context.table) "yes"}}
      >{{(@renderValue)}}</span>
    </template>
    const Direct = <template>
      <em>direct</em>
    </template>
    const simple = createTable({
      features: coreOnly,
      data: FIVE.slice(0, 2),
      columns: helper.columns([
        helper.display({ id: 'text', header: 'Text', cell: 'fixed' }),
        helper.display({ id: 'fn', header: () => 'Function', cell: ({ row }) => row.index * 10 }),
        helper.display({ id: 'none', header: 'None', cell: () => null }),
        helper.display({ id: 'bool', header: () => 'Bool', cell: () => false }),
        helper.accessor('email', { id: 'args', header: 'Args', cell: flexComponent(CellArgs) }),
        // A component given as it is, which table-core's types don't allow for, renders too.
        helper.display({ id: 'direct', header: 'Direct', cell: Direct as never }),
      ]),
    })
    assert.strictEqual(simple.FlexRender, FlexRender, 'the table carries FlexRender')

    await render(
      <template>
        <Table as |t|>
          <t.Header>
            {{#each (simple.getHeaderGroups) as |group|}}
              <t.Row>
                {{#each group.headers as |header|}}
                  <t.Head><FlexRender @header={{header}} /></t.Head>
                {{/each}}
              </t.Row>
            {{/each}}
          </t.Header>
          <t.Body>
            {{#let (simple.getRowModel) as |model|}}
              {{#each model.rows as |row|}}
                <t.Row>
                  {{! Without the column visibility feature, every cell shows. }}
                  {{#each (row.getAllCells) as |cell|}}
                    <t.Cell><simple.FlexRender @cell={{cell}} /></t.Cell>
                  {{/each}}
                </t.Row>
              {{/each}}
            {{/let}}
          </t.Body>
        </Table>
      </template>,
    )
    const table = new TableHarness()
    assert.deepEqual(table.columns, ['Text', 'Function', 'None', 'Bool', 'Args', 'Direct'])
    assert.deepEqual(table.rows, [
      ['fixed', '0', '', '', 'ken99@example.com', 'direct'],
      ['fixed', '10', '', '', 'Abe45@example.com', 'direct'],
    ])
    const [args] = document.querySelectorAll('[data-case="args"]')
    assert.dom(args).hasAttribute('data-row', '0')
    assert.dom(args).hasAttribute('data-column', 'args')
    assert.dom(args).hasAttribute('data-cell', '0_args')
    assert.dom(args).hasAttribute('data-value', 'ken99@example.com')
    assert.dom(args).hasAttribute('data-same-table', 'yes', '@table is the context’s table')
    assert.strictEqual(
      table.cell(0, 'Function').innerHTML,
      '0',
      'a value renders as text, with nothing around it',
    )
    assert.strictEqual(table.cell(0, 'None').innerHTML, '', 'null renders nothing')
    assert.strictEqual(table.cell(0, 'Bool').innerHTML, '', 'false renders nothing')
    await a11yAudit()
  })

  test('it renders upstream’s data table: the root, and each part marked for its harness', async function (assert) {
    const state = new State()
    await render(<template><Payments @state={{state}} /></template>)
    const payments = new DataTableHarness('payments')

    assert.dom(payments.element).hasTagName('div').hasClass('w-full')
    assert.dom(payments.element).hasAttribute('data-test-jn', 'data-table')
    assert.dom(payments.element).hasAttribute('data-test-jn-name', 'payments')
    assert.dom(payments.element).doesNotHaveAttribute('data-slot', 'it adds no styles of its own')
    const id = payments.element.id
    assert.ok(id, 'it has an id, which its parts name')

    assert.deepEqual(payments.columnIds, ['select', 'status', 'email', 'amount'])
    assert.deepEqual(payments.columns, ['', 'Status', 'Email', 'Amount'])
    assert.deepEqual(payments.rowIds, ['0', '1', '2', '3', '4'])
    assert.deepEqual(payments.column('email'), [
      'ken99@example.com',
      'abe45@example.com',
      'monserrat44@example.com',
      'silas22@example.com',
      'carmella@example.com',
    ])
    assert.deepEqual(payments.column('Amount'), [
      '$316.00',
      '$242.00',
      '$837.00',
      '$874.00',
      '$721.00',
    ])
    assert.strictEqual(payments.cell(4, 'status').textContent, 'failed')

    for (const element of [
      ...payments.headElements,
      ...payments.rowElements,
      payments.filterInput('email'),
      payments.previousPageButton!,
      payments.nextPageButton!,
      payments.viewOptions.element,
    ]) {
      assert.dom(element).hasAttribute('data-test-jn-owner', id)
    }
    assert.dom(payments.head('email')).hasClass('jn-table-head', 'still Table’s header cell')
    assert.dom(payments.row(0)).hasClass('jn-table-row', 'still Table’s row')
    assert.dom(payments.head('email')).doesNotHaveAttribute('aria-sort', 'unsorted')
    assert.dom(payments.head('email')).doesNotHaveAttribute('colspan')
    assert.false(payments.isEmpty)
    assert.strictEqual(payments.emptyText, null)
    assert.strictEqual(payments.table.rowCount, 5, 'its table is the TableHarness inside')
    await a11yAudit()
  })

  test('@as renders another tag, and a caller’s id is the one its parts name', async function (assert) {
    const table = createTable({ features, data: FIVE, columns })
    await render(
      <template>
        <DataTable @table={{table}} @as="section" id="mine" aria-label="Payments" as |dt|>
          <Table as |t|>
            <t.Body>
              {{#let (table.getRowModel) as |model|}}
                {{#each model.rows as |row|}}
                  <t.Row {{dt.row row}}>
                    <t.Cell>{{row.id}}</t.Cell>
                  </t.Row>
                {{/each}}
              {{/let}}
            </t.Body>
          </Table>
        </DataTable>
      </template>,
    )
    const harness = new DataTableHarness()
    assert.dom(harness.element).hasTagName('section').hasAttribute('id', 'mine')
    assert.dom(harness.row(0)).hasAttribute('data-test-jn-owner', 'mine')
    assert.deepEqual(harness.rowIds, ['0', '1', '2', '3', '4'])
    await a11yAudit()
  })

  test('sorting: a header’s button sorts by its column, and its cell says how in aria-sort', async function (assert) {
    const state = new State()
    await render(<template><Payments @state={{state}} /></template>)
    const payments = new DataTableHarness('payments')
    assert.strictEqual(payments.sortedBy, null)
    assert.strictEqual(payments.sortOf('email'), 'none')

    await payments.sort('email')
    assert.strictEqual(payments.sortOf('email'), 'ascending')
    assert.dom(payments.head('email')).hasAttribute('aria-sort', 'ascending')
    assert.deepEqual(payments.sortedBy, { column: 'email', direction: 'ascending' })
    assert.deepEqual(payments.column('email'), [
      'abe45@example.com',
      'carmella@example.com',
      'ken99@example.com',
      'monserrat44@example.com',
      'silas22@example.com',
    ])

    await payments.sort('Email')
    assert.strictEqual(payments.sortOf('email'), 'descending')
    assert.deepEqual(payments.column('email').at(0), 'silas22@example.com')
    for (const other of ['select', 'status', 'amount']) {
      assert.dom(payments.head(other)).doesNotHaveAttribute('aria-sort', `${other} isn’t sorted`)
    }

    // Sorting by another column moves aria-sort to it: ARIA wants it on one header at a time.
    state.table!.setSorting([
      { id: 'amount', desc: false },
      { id: 'email', desc: true },
    ])
    await settled()
    assert.strictEqual(payments.sortOf('amount'), 'ascending')
    assert.strictEqual(payments.sortOf('email'), 'none', 'only the first sort is announced')
    assert.deepEqual(payments.column('amount'), [
      '$242.00',
      '$316.00',
      '$721.00',
      '$837.00',
      '$874.00',
    ])
    assert.strictEqual(state.table!.state.sorting.length, 2, 'table.state is the whole state')
    await a11yAudit()
  })

  test('filtering: the filter narrows the rows, and an empty table says so', async function (assert) {
    const state = new State()
    await render(<template><Payments @state={{state}} /></template>)
    const payments = new DataTableHarness('payments')

    await payments.filter('ken')
    assert.strictEqual(payments.filterValue('email'), 'ken')
    assert.strictEqual(payments.filterValue(), 'ken', 'the first filter, without a column')
    assert.deepEqual(payments.column('email'), ['ken99@example.com'])
    assert.deepEqual(state.table!.state.columnFilters, [{ id: 'email', value: 'ken' }])

    await payments.filter('nobody')
    assert.true(payments.isEmpty)
    assert.strictEqual(payments.rowCount, 0)
    assert.strictEqual(payments.emptyText, 'No results.')

    await payments.filter('')
    assert.strictEqual(payments.rowCount, 5)
    assert.deepEqual(state.table!.state.columnFilters, [], 'an empty filter goes away')
    await a11yAudit()
  })

  test('pagination: ten rows a page, with previous and next', async function (assert) {
    const state = new State()
    state.data = TWELVE
    await render(<template><Payments @state={{state}} /></template>)
    const payments = new DataTableHarness('payments')

    assert.strictEqual(payments.rowCount, 10)
    assert.false(payments.canPreviousPage)
    assert.true(payments.canNextPage)
    assert.dom(payments.previousPageButton).isDisabled()

    await payments.nextPage()
    assert.deepEqual(payments.column('email'), ['user11@example.com', 'user12@example.com'])
    assert.true(payments.canPreviousPage)
    assert.false(payments.canNextPage)
    assert.dom(payments.nextPageButton).isDisabled()

    await payments.previousPage()
    assert.strictEqual(payments.rowCount, 10)
    assert.strictEqual(payments.column('email')[0], 'user01@example.com')

    // A filter that changes the rows goes back to the first page, after the render that saw it.
    await payments.nextPage()
    await payments.filter('user1')
    assert.strictEqual(state.table!.state.pagination.pageIndex, 0, 'back on the first page')
    assert.deepEqual(payments.column('email'), [
      'user10@example.com',
      'user11@example.com',
      'user12@example.com',
    ])
    await a11yAudit()
  })

  test('selection: each row’s checkbox selects it, and the header’s selects the page', async function (assert) {
    const state = new State()
    await render(<template><Payments @state={{state}} /></template>)
    const payments = new DataTableHarness('payments')

    assert.deepEqual(payments.selectedRows, [])
    assert.strictEqual(payments.selectAll!.state, 'unchecked')
    assert.strictEqual(payments.rowCheckbox(0)!.label, 'Select row')
    assert.strictEqual(payments.selectAll!.label, 'Select all')
    assert.strictEqual(countText(), '0 of 5 row(s) selected.')

    await payments.toggleRow(1)
    assert.deepEqual(payments.selectedRows, [1])
    assert.true(payments.isSelected(1))
    assert.dom(payments.row(1)).hasAttribute('data-state', 'selected')
    assert.dom(payments.row(0)).doesNotHaveAttribute('data-state')
    assert.strictEqual(payments.selectAll!.state, 'indeterminate')
    assert.strictEqual(countText(), '1 of 5 row(s) selected.')

    await payments.toggleAll()
    assert.deepEqual(payments.selectedRows, [0, 1, 2, 3, 4])
    assert.strictEqual(payments.selectAll!.state, 'checked')
    assert.deepEqual(Object.keys(state.table!.state.rowSelection), ['0', '1', '2', '3', '4'])

    await payments.toggleAll()
    assert.deepEqual(payments.selectedRows, [])

    // Selection follows the row, not its place: sorting keeps it.
    await payments.toggleRow(0)
    await payments.sort('email')
    assert.deepEqual(payments.selectedRows, [2], 'ken99 moved to third')
    await a11yAudit()
  })

  test('column visibility: the column menu shows and hides the columns that can hide', async function (assert) {
    const state = new State()
    await render(<template><Payments @state={{state}} /></template>)
    const payments = new DataTableHarness('payments')

    assert.deepEqual(await payments.columnOptions(), ['status', 'email', 'amount'])
    assert.true(payments.viewOptions.isChecked('status'))
    await payments.viewOptions.close()

    await payments.toggleColumn('status')
    assert.false(payments.isColumnShown('status'))
    assert.deepEqual(payments.columnIds, ['select', 'email', 'amount'])
    assert.strictEqual(payments.rows[0]!.length, 3, 'its cells go too')
    assert.deepEqual(payments.column('email')[0], 'ken99@example.com', 'by id, where it is now')
    await payments.viewOptions.open()
    assert.false(payments.viewOptions.isChecked('status'))
    await payments.viewOptions.close()

    await payments.toggleColumn('status')
    assert.true(payments.isColumnShown('status'))
    assert.deepEqual(payments.columnIds, ['select', 'status', 'email', 'amount'])
    await a11yAudit()
  })

  test('controlled: the state it is given wins, and changes come back through on<Slice>Change', async function (assert) {
    const state = new State()
    await render(<template><Payments @state={{state}} @controlled={{true}} /></template>)
    const payments = new DataTableHarness('payments')
    const given = () => state.table!.options as unknown as { state: { sorting: SortingState } }
    assert.deepEqual(given().state.sorting, [])

    await payments.sort('email')
    assert.deepEqual(
      given().state.sorting,
      [{ id: 'email', desc: false }],
      'set through tableState',
    )
    assert.strictEqual(payments.sortOf('email'), 'ascending')

    await payments.filter('ilas')
    assert.deepEqual(state.table!.state.columnFilters, [{ id: 'email', value: 'ilas' }])
    assert.deepEqual(payments.column('email'), ['silas22@example.com'])
    await a11yAudit()
  })

  test('uncontrolled: it keeps its own state, starting from initialState', async function (assert) {
    const state = new State()
    const initialState = { sorting: [{ id: 'amount', desc: true }] }
    await render(<template><Payments @state={{state}} @initialState={{initialState}} /></template>)
    const payments = new DataTableHarness('payments')
    assert.strictEqual(payments.sortOf('amount'), 'descending')
    assert.deepEqual(payments.column('amount'), [
      '$874.00',
      '$837.00',
      '$721.00',
      '$316.00',
      '$242.00',
    ])

    state.table!.resetSorting()
    await settled()
    assert.strictEqual(payments.sortOf('amount'), 'descending', 'reset goes back to initialState')
    state.table!.resetSorting(true)
    await settled()
    assert.strictEqual(payments.sortedBy, null, 'and with true, to no sort at all')
    await a11yAudit()
  })

  test('its options follow what they read: new data re-renders the rows', async function (assert) {
    const state = new State()
    await render(<template><Payments @state={{state}} /></template>)
    const payments = new DataTableHarness('payments')
    await payments.toggleRow(0)

    state.data = [...FIVE, { id: 'new', amount: 1, status: 'pending', email: 'new@example.com' }]
    await rerender()
    assert.strictEqual(payments.rowCount, 6)
    assert.strictEqual(payments.column('email').at(-1), 'new@example.com')
    assert.deepEqual(payments.selectedRows, [0], 'its state stays')

    state.data = []
    await rerender()
    assert.strictEqual(payments.emptyText, 'No results.')
    await a11yAudit()
  })

  test('setOptions changes what it is given, on top of the options function', async function (assert) {
    const state = new State()
    await render(<template><Payments @state={{state}} /></template>)
    const payments = new DataTableHarness('payments')

    assert.true(state.table!.getColumn('email')!.getCanSort())
    state.table!.setOptions(previous => ({ ...previous, manualSorting: true }))
    await settled()
    assert.true(state.table!.options.manualSorting)
    await payments.sort('email')
    assert.strictEqual(payments.sortOf('email'), 'ascending', 'the sort is set')
    assert.strictEqual(
      payments.column('email')[0],
      'ken99@example.com',
      'but the rows are left as they came: sorting is manual now',
    )

    state.data = FIVE.slice(0, 2)
    await rerender()
    assert.strictEqual(payments.rowCount, 2, 'what the function reads still follows')
    await a11yAudit()
  })

  test('keyboard: every control is a native one in the tab order, in reading order', async function (assert) {
    const state = new State()
    await render(<template><Payments @state={{state}} /></template>)
    const payments = new DataTableHarness('payments')

    const order = tabOrder(payments.element)
    assert.strictEqual(order[0], payments.filterInput('email'), 'the filter first')
    assert.strictEqual(order[1], payments.viewOptions.trigger, 'then the column menu')
    assert.strictEqual(order[2], payments.selectAll!.element, 'then select all')
    assert.strictEqual(order[3], payments.sortButton('email'), 'then the sort button')
    assert.strictEqual(order[4], payments.rowCheckbox(0)!.element, 'then each row')
    assert.ok(
      payments.sortButton('email') instanceof HTMLButtonElement,
      'a native <button>: Enter and Space sort (APG sortable table)',
    )
    assert.notOk(order.includes(payments.previousPageButton!), 'a disabled page button is skipped')

    // A row's checkbox takes focus with Tab, and keeps it while its row re-renders.
    payments.filterInput('email').focus()
    await tab()
    await tab()
    await tab()
    await tab()
    assert.dom(payments.rowCheckbox(0)!.element).isFocused()
    assert.true(await pressKey('Enter'), 'Enter does nothing to a checkbox (APG)')
    await click(payments.rowCheckbox(0)!.element)
    assert.dom(payments.rowCheckbox(0)!.element).isFocused('still focused after it re-rendered')
    assert.true(payments.isSelected(0))

    // The sort button: focus stays on it as the rows reorder.
    const sort = new ButtonHarness({ within: payments.head('email') })
    await sort.focus()
    await sort.click()
    assert.true(sort.isFocused)
    assert.strictEqual(payments.sortOf('email'), 'ascending')
    await a11yAudit()
  })

  test('right to left: the columns run from the right, and the parts are the same', async function (assert) {
    const state = new State()
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Payments @state={{state}} />
        </DirectionProvider>
      </template>,
    )
    const payments = new DataTableHarness('payments')
    const [select, , , amount] = payments.columnHeads
    assert.true(
      select!.getBoundingClientRect().left > amount!.getBoundingClientRect().left,
      'the first column is at the right',
    )
    assert.strictEqual(getComputedStyle(payments.head('status')).textAlign, 'start')
    assert.strictEqual(getComputedStyle(payments.table.table).direction, 'rtl')
    await payments.sort('email')
    assert.strictEqual(payments.sortOf('email'), 'ascending')
    assert.deepEqual(payments.columnIds, ['select', 'status', 'email', 'amount'], 'reading order')
    await a11yAudit()
  })

  test('emberReactivity() makes a table of table-core’s own constructTable() tracked', async function (assert) {
    const bareFeatures = tableFeatures({
      coreReactivityFeature: emberReactivity(),
      rowSortingFeature,
      sortedRowModel: createSortedRowModel(),
      sortFns: { alphanumeric: sortFn_alphanumeric, text: sortFn_text },
    })
    const bareColumns = createColumnHelper<typeof bareFeatures, Payment>()
    const bare = constructTable({
      features: bareFeatures,
      data: FIVE,
      columns: bareColumns.columns([bareColumns.accessor('email', { header: 'Email' })]),
    })
    const sorting = tableState<SortingState>([])
    await render(
      <template>
        <ol>
          {{#let (bare.getRowModel) as |model|}}
            {{#each model.rows as |row|}}
              <li data-case="email">{{row.original.email}}</li>
            {{/each}}
          {{/let}}
        </ol>
        <p data-case="sorting">{{sorting.value.length}}</p>
      </template>,
    )
    const emails = () =>
      [...document.querySelectorAll('[data-case="email"]')].map(item => item.textContent)
    assert.strictEqual(emails()[0], 'ken99@example.com')
    bare.setSorting([{ id: 'email', desc: true }])
    await settled()
    assert.strictEqual(emails()[0], 'Silas22@example.com', 'its state is tracked')

    sorting.set([{ id: 'email', desc: false }])
    sorting.set(old => [...old, { id: 'amount', desc: true }])
    await settled()
    assert.dom('[data-case="sorting"]').hasText('2', 'tableState takes values and updaters')
    await a11yAudit()
  })

  test('the harness says what is missing', async function (assert) {
    const table = createTable({ features, data: FIVE, columns })
    await render(
      <template>
        <DataTable @table={{table}} as |dt|>
          <Table as |t|>
            <t.Header>
              {{#each (table.getHeaderGroups) as |group|}}
                <t.Row>
                  {{#each group.headers as |header|}}
                    <t.Head {{dt.head header}}>{{header.id}}</t.Head>
                  {{/each}}
                </t.Row>
              {{/each}}
            </t.Header>
            <t.Body>
              {{#let (table.getRowModel) as |model|}}
                {{#each model.rows as |row|}}
                  <t.Row data-state={{if (row.getIsSelected) "selected"}} {{dt.row row}}>
                    <t.Cell>{{row.id}}</t.Cell>
                  </t.Row>
                {{/each}}
              {{/let}}
            </t.Body>
          </Table>
        </DataTable>
      </template>,
    )
    const harness = new DataTableHarness()
    assert.throws(() => harness.filterInput(), /no filter in data-table/)
    assert.throws(() => harness.filterInput('email'), /no filter for "email"/)
    assert.throws(() => harness.head('nope'), /no column "nope".*"select", "status"/)
    assert.throws(() => harness.sortButton('status'), /has no sort button/)
    assert.throws(() => harness.row(9), /no row 9 .*it has 5/)
    assert.throws(() => harness.viewOptions, /no column menu/)
    assert.strictEqual(harness.rowCheckbox(0), null)
    assert.strictEqual(harness.selectAll, null)
    assert.false(harness.canNextPage, 'no page buttons: nowhere to go')
    await assert.rejects(harness.nextPage(), /no next page button/)

    // Without checkboxes, a row's selection is its data-state.
    table.getRow('2').toggleSelected(true)
    await settled()
    assert.deepEqual(harness.selectedRows, [2])
    await a11yAudit()
  })
})
