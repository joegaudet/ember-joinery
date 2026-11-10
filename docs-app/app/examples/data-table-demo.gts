import Component from '@glimmer/component'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import { ArrowUpDown, ChevronDown, MoreHorizontal } from 'lucide'
import { Button, Checkbox, DropdownMenu, Icon, Input, Table } from '@ember-joinery/ember'
import type { CheckedState } from '@ember-joinery/primitives/checkbox'
import {
  DataTable,
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
  tableState,
  type CellComponentSignature,
  type Column,
  type ColumnFiltersState,
  type ColumnVisibilityState,
  type HeaderComponentSignature,
  type Row,
  type RowSelectionState,
  type SortingState,
  type Table as TanStackTable,
} from '@ember-joinery/data-table'

// New in v9: declare the features this table uses — anything you don't
// register is tree-shaken out of the bundle.
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

const columnHelper = createColumnHelper<typeof features, Payment>()

const data: Payment[] = [
  {
    id: 'm5gr84i9',
    amount: 316,
    status: 'success',
    email: 'ken99@example.com',
  },
  {
    id: '3u1reuv4',
    amount: 242,
    status: 'success',
    email: 'Abe45@example.com',
  },
  {
    id: 'derv1ws0',
    amount: 837,
    status: 'processing',
    email: 'Monserrat44@example.com',
  },
  {
    id: '5kma53ae',
    amount: 874,
    status: 'success',
    email: 'Silas22@example.com',
  },
  {
    id: 'bhqecj4p',
    amount: 721,
    status: 'failed',
    email: 'carmella@example.com',
  },
]

export type Payment = {
  id: string
  amount: number
  status: 'pending' | 'processing' | 'success' | 'failed'
  email: string
}

type Features = typeof features

// What upstream writes inline in each column's JSX: a template calls them.
const pageSelection = (table: TanStackTable<Features, Payment>): CheckedState =>
  table.getIsAllPageRowsSelected() || (table.getIsSomePageRowsSelected() && 'indeterminate')
const toggleAllPageRows = (table: TanStackTable<Features, Payment>, value: CheckedState) =>
  table.toggleAllPageRowsSelected(!!value)
const toggleRow = (row: Row<Features, Payment>, value: CheckedState) => row.toggleSelected(!!value)
const toggleSorting = (column: Column<Features, Payment>) =>
  column.toggleSorting(column.getIsSorted() === 'asc')
const copyPaymentId = (payment: Payment) => navigator.clipboard.writeText(payment.id)
// Format the amount as a dollar amount.
const formatted = (amount: unknown) =>
  new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(parseFloat(String(amount)))
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

const StatusCell: TOC<CellComponentSignature<Features, Payment>> = <template>
  <div class="capitalize">{{@row.getValue "status"}}</div>
</template>

const EmailHeader: TOC<HeaderComponentSignature<Features, Payment>> = <template>
  <Button @variant="ghost" {{on "click" (fn toggleSorting @column)}}>
    Email
    <Icon @icon={{ArrowUpDown}} />
  </Button>
</template>

const EmailCell: TOC<CellComponentSignature<Features, Payment>> = <template>
  <div class="lowercase">{{@row.getValue "email"}}</div>
</template>

const AmountHeader = <template>
  <div class="text-right">Amount</div>
</template>

const AmountCell: TOC<CellComponentSignature<Features, Payment>> = <template>
  <div class="text-right font-medium">{{formatted (@row.getValue "amount")}}</div>
</template>

// Upstream's actions column has no header; a visually hidden one names its cells' column, as
// a header cell must have a name (axe's empty-table-header).
const ActionsHeader = <template>
  <span class="sr-only">Actions</span>
</template>

const Actions: TOC<CellComponentSignature<Features, Payment>> = <template>
  {{#let @row.original as |payment|}}
    <DropdownMenu as |m|>
      <Button @variant="ghost" @size="icon-xs" {{m.trigger}}>
        <span class="sr-only">Open menu</span>
        <Icon @icon={{MoreHorizontal}} />
      </Button>
      <m.Content @align="end" class="w-40">
        <m.Group>
          <m.Label>Actions</m.Label>
          <m.Item {{on "click" (fn copyPaymentId payment)}}>
            Copy payment ID
          </m.Item>
        </m.Group>
        <m.Group>
          <m.Item>View customer</m.Item>
          <m.Item>View payment details</m.Item>
        </m.Group>
      </m.Content>
    </DropdownMenu>
  {{/let}}
</template>

export const columns = columnHelper.columns([
  columnHelper.display({
    id: 'select',
    header: flexComponent(SelectAll),
    cell: flexComponent(SelectRow),
    enableSorting: false,
    enableHiding: false,
  }),
  columnHelper.accessor('status', {
    header: 'Status',
    cell: flexComponent(StatusCell),
  }),
  columnHelper.accessor('email', {
    header: flexComponent(EmailHeader),
    cell: flexComponent(EmailCell),
  }),
  columnHelper.accessor('amount', {
    header: flexComponent(AmountHeader),
    cell: flexComponent(AmountCell),
  }),
  columnHelper.display({
    id: 'actions',
    enableHiding: false,
    header: flexComponent(ActionsHeader),
    cell: flexComponent(Actions),
  }),
])

// DataTable marks each part for DataTableHarness (dt.filter, dt.head, dt.row…), and gives the
// header cells the aria-sort upstream's leave out.
export default class DataTableDemo extends Component {
  sorting = tableState<SortingState>([])
  columnFilters = tableState<ColumnFiltersState>([])
  columnVisibility = tableState<ColumnVisibilityState>({})
  rowSelection = tableState<RowSelectionState>({})

  table = createTable(() => ({
    features,
    data,
    columns,
    onSortingChange: this.sorting.set,
    onColumnFiltersChange: this.columnFilters.set,
    onColumnVisibilityChange: this.columnVisibility.set,
    onRowSelectionChange: this.rowSelection.set,
    state: {
      sorting: this.sorting.value,
      columnFilters: this.columnFilters.value,
      columnVisibility: this.columnVisibility.value,
      rowSelection: this.rowSelection.value,
    },
  }))

  get emailFilter(): string {
    return (this.table.getColumn('email')?.getFilterValue() as string) ?? ''
  }

  filterEmails = (value: string) => this.table.getColumn('email')?.setFilterValue(value)

  get hideableColumns() {
    return this.table.getAllColumns().filter(column => column.getCanHide())
  }

  <template>
    <DataTable @table={{this.table}} class="w-full" as |dt|>
      <div class="flex items-center py-4">
        <Input
          placeholder="Filter emails..."
          @value={{this.emailFilter}}
          @onValueChange={{this.filterEmails}}
          class="max-w-sm"
          {{dt.filter "email"}}
        />
        <DropdownMenu {{dt.viewOptions}} as |m|>
          <Button @variant="outline" class="ml-auto" {{m.trigger}}>
            Columns
            <Icon @icon={{ChevronDown}} />
          </Button>
          <m.Content @align="end">
            <m.Group>
              {{#each this.hideableColumns key="id" as |column|}}
                <m.CheckboxItem
                  class="capitalize"
                  @checked={{(column.getIsVisible)}}
                  @onCheckedChange={{column.toggleVisibility}}
                >
                  {{column.id}}
                </m.CheckboxItem>
              {{/each}}
            </m.Group>
          </m.Content>
        </DropdownMenu>
      </div>
      <div class="overflow-hidden rounded-md border">
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
            {{#let (this.table.getRowModel) as |rowModel|}}
              {{#each rowModel.rows key="id" as |row|}}
                <t.Row data-state={{if (row.getIsSelected) "selected"}} {{dt.row row}}>
                  {{#each (row.getVisibleCells) key="id" as |cell|}}
                    <t.Cell>
                      <this.table.FlexRender @cell={{cell}} />
                    </t.Cell>
                  {{/each}}
                </t.Row>
              {{else}}
                <t.Row>
                  <t.Cell colspan={{columns.length}} class="h-24 text-center">
                    No results.
                  </t.Cell>
                </t.Row>
              {{/each}}
            {{/let}}
          </t.Body>
        </Table>
      </div>
      <div class="flex items-center justify-end space-x-2 py-4">
        <div class="flex-1 text-sm text-muted-foreground">
          {{#let
            (this.table.getFilteredSelectedRowModel) (this.table.getFilteredRowModel)
            as |selected filtered|
          }}
            {{selected.rows.length}}
            of
            {{filtered.rows.length}}
            row(s) selected.
          {{/let}}
        </div>
        <div class="space-x-2">
          <Button
            @variant="outline"
            @size="sm"
            disabled={{not (this.table.getCanPreviousPage)}}
            {{on "click" this.table.previousPage}}
            {{dt.previousPage}}
          >
            Previous
          </Button>
          {{~! React puts no space between the buttons, so neither does this ~}}
          <Button
            @variant="outline"
            @size="sm"
            disabled={{not (this.table.getCanNextPage)}}
            {{on "click" this.table.nextPage}}
            {{dt.nextPage}}
          >
            Next
          </Button>
        </div>
      </div>
    </DataTable>
  </template>
}
