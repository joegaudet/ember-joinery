import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import {
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  CircleCheck,
  Columns3,
  EllipsisVertical,
  GripVertical,
  Loader,
  Plus,
  TrendingUp,
} from 'lucide'
import {
  Badge,
  Button,
  Checkbox,
  Drawer,
  DropdownMenu,
  Icon,
  Input,
  Label,
  Select,
  Separator,
  Table,
  Tabs,
  UseSidebar,
  toast,
} from '@ember-joinery/ember'
import type { CheckedState } from '@ember-joinery/primitives/checkbox'
import { idFor } from '@ember-joinery/primitives/id'
import { ChartContainer, ChartTooltipContent, type ChartConfig } from '@ember-joinery/chart'
import {
  DataTable as DataTableRoot,
  columnFilteringFeature,
  columnVisibilityFeature,
  createColumnHelper,
  createFilteredRowModel,
  createPaginatedRowModel,
  createSortedRowModel,
  createTable,
  flexComponent,
  rowPaginationFeature,
  rowSelectionFeature,
  rowSortingFeature,
  tableFeatures,
  tableState,
  type CellComponentSignature,
  type ColumnFiltersState,
  type ColumnVisibilityState,
  type HeaderComponentSignature,
  type Row,
  type RowSelectionState,
  type SortingState,
  type Table as TanStackTable,
} from '@ember-joinery/data-table'
import { SORTABLE_INSTRUCTIONS, SortableRows, type SortableId } from './sortable.ts'
import type { Section } from './data.ts'

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
})

type Features = typeof features

// Upstream infers the row's type from a zod schema; Joinery takes no zod, so it is an
// interface (data.ts).
const columnHelper = createColumnHelper<Features, Section>()

/** What the table carries for its cells: the sortable rows their drag handles move. */
interface DashboardTableMeta {
  sortable: SortableRows
}

const sortableOf = (table: TanStackTable<Features, Section>): SortableRows =>
  (table.options.meta as DashboardTableMeta).sortable

// What upstream writes inline in each column's JSX: a template calls them.
const pageSelection = (table: TanStackTable<Features, Section>): CheckedState =>
  table.getIsAllPageRowsSelected() || (table.getIsSomePageRowsSelected() && 'indeterminate')
const toggleAllPageRows = (table: TanStackTable<Features, Section>, value: CheckedState) =>
  table.toggleAllPageRowsSelected(!!value)
const toggleRow = (row: Row<Features, Section>, value: CheckedState) => row.toggleSelected(!!value)
const isDone = (status: string) => status === 'Done'
const isAssigned = (reviewer: string) => reviewer !== 'Assign reviewer'
const not = (value: boolean) => !value
const fieldId = (id: number, field: string) => `${id}-${field}`

const save = (header: string, event: SubmitEvent) => {
  event.preventDefault()
  toast.promise(new Promise(resolve => setTimeout(resolve, 1000)), {
    loading: `Saving ${header}`,
    success: 'Done',
    error: 'Error',
  })
}

// Create a separate component for the drag handle
// (upstream's useSortable() hands it dnd-kit's attributes and listeners; here the table's
// sortable rows give it a modifier, through the table's meta).
const DragHandle: TOC<CellComponentSignature<Features, Section>> = <template>
  {{#let (sortableOf @table) as |sortable|}}
    <Button
      @variant="ghost"
      @size="icon"
      class="size-7 text-muted-foreground hover:bg-transparent"
      {{sortable.handle @row.original.id}}
    >
      <Icon @icon={{GripVertical}} class="size-3 text-muted-foreground" />
      <span class="sr-only">Drag to reorder</span>
    </Button>
  {{/let}}
</template>

// Upstream's drag column has an empty header (`() => null`), and its actions column none; a
// header cell must have a name (axe's empty-table-header), so each has a visually hidden one.
const DragHeader: TOC<HeaderComponentSignature<Features, Section>> = <template>
  <span class="sr-only">Reorder</span>
</template>

const ActionsHeader: TOC<HeaderComponentSignature<Features, Section>> = <template>
  <span class="sr-only">Actions</span>
</template>

const SelectAll: TOC<HeaderComponentSignature<Features, Section>> = <template>
  <div class="flex items-center justify-center">
    <Checkbox
      @checked={{pageSelection @table}}
      @onCheckedChange={{fn toggleAllPageRows @table}}
      aria-label="Select all"
    />
  </div>
</template>

const SelectRow: TOC<CellComponentSignature<Features, Section>> = <template>
  <div class="flex items-center justify-center">
    <Checkbox
      @checked={{(@row.getIsSelected)}}
      @onCheckedChange={{fn toggleRow @row}}
      aria-label="Select row"
    />
  </div>
</template>

const TypeCell: TOC<CellComponentSignature<Features, Section>> = <template>
  <div class="w-32">
    <Badge @variant="outline" class="px-1.5 text-muted-foreground">
      {{@row.original.type}}
    </Badge>
  </div>
</template>

const StatusCell: TOC<CellComponentSignature<Features, Section>> = <template>
  <Badge @variant="outline" class="px-1.5 text-muted-foreground">
    {{#if (isDone @row.original.status)}}
      <Icon @icon={{CircleCheck}} class="fill-green-500 dark:fill-green-400" />
    {{else}}
      <Icon @icon={{Loader}} />
    {{/if}}
    {{@row.original.status}}
  </Badge>
</template>

const TargetHeader: TOC<HeaderComponentSignature<Features, Section>> = <template>
  <div class="w-full text-right">Target</div>
</template>

const LimitHeader: TOC<HeaderComponentSignature<Features, Section>> = <template>
  <div class="w-full text-right">Limit</div>
</template>

const TargetCell: TOC<CellComponentSignature<Features, Section>> = <template>
  <form {{on "submit" (fn save @row.original.header)}}>
    <Label for={{fieldId @row.original.id "target"}} class="sr-only">
      Target
    </Label>
    <Input
      class="h-8 w-16 border-transparent bg-transparent text-right shadow-none hover:bg-input/30 focus-visible:border focus-visible:bg-background dark:bg-transparent dark:hover:bg-input/30 dark:focus-visible:bg-input/30"
      @defaultValue={{@row.original.target}}
      id={{fieldId @row.original.id "target"}}
    />
  </form>
</template>

const LimitCell: TOC<CellComponentSignature<Features, Section>> = <template>
  <form {{on "submit" (fn save @row.original.header)}}>
    <Label for={{fieldId @row.original.id "limit"}} class="sr-only">
      Limit
    </Label>
    <Input
      class="h-8 w-16 border-transparent bg-transparent text-right shadow-none hover:bg-input/30 focus-visible:border focus-visible:bg-background dark:bg-transparent dark:hover:bg-input/30 dark:focus-visible:bg-input/30"
      @defaultValue={{@row.original.limit}}
      id={{fieldId @row.original.id "limit"}}
    />
  </form>
</template>

const ReviewerCell: TOC<CellComponentSignature<Features, Section>> = <template>
  {{#if (isAssigned @row.original.reviewer)}}
    {{@row.original.reviewer}}
  {{else}}
    <Label for={{fieldId @row.original.id "reviewer"}} class="sr-only">
      Reviewer
    </Label>
    <Select as |s|>
      <s.Trigger
        class="w-38 **:data-[slot=select-value]:block **:data-[slot=select-value]:truncate"
        @size="sm"
        id={{fieldId @row.original.id "reviewer"}}
      >
        <s.Value @placeholder="Assign reviewer" />
      </s.Trigger>
      <s.Content @align="end">
        <s.Group>
          <s.Item @value="Eddie Lake">Eddie Lake</s.Item>
          <s.Item @value="Jamik Tashpulatov">
            Jamik Tashpulatov
          </s.Item>
        </s.Group>
      </s.Content>
    </Select>
  {{/if}}
</template>

const Actions: TOC<CellComponentSignature<Features, Section>> = <template>
  <DropdownMenu as |m|>
    <Button
      @variant="ghost"
      class="flex size-8 text-muted-foreground data-[state=open]:bg-muted"
      @size="icon"
      {{m.trigger}}
    >
      <Icon @icon={{EllipsisVertical}} />
      <span class="sr-only">Open menu</span>
    </Button>
    <m.Content @align="end" class="w-32">
      <m.Item>Edit</m.Item>
      <m.Item>Make a copy</m.Item>
      <m.Item>Favorite</m.Item>
      <m.Separator />
      <m.Item @variant="destructive">Delete</m.Item>
    </m.Content>
  </DropdownMenu>
</template>

const chartData = [
  { month: 'January', desktop: 186, mobile: 80 },
  { month: 'February', desktop: 305, mobile: 200 },
  { month: 'March', desktop: 237, mobile: 120 },
  { month: 'April', desktop: 73, mobile: 190 },
  { month: 'May', desktop: 209, mobile: 130 },
  { month: 'June', desktop: 214, mobile: 140 },
]

const chartConfig = {
  desktop: {
    label: 'Desktop',
    color: 'var(--primary)',
  },
  mobile: {
    label: 'Mobile',
    color: 'var(--primary)',
  },
} satisfies ChartConfig

const chartMargin = { left: 0, right: 10 }
const monthAbbr = (value: string) => value.slice(0, 3)

/**
 * The header cell's drawer, with the section's chart and form. Upstream's `useIsMobile()` picks
 * its side; here the sidebar's provider says, through `<UseSidebar>`, at the same breakpoint.
 */
const TableCellViewer: TOC<CellComponentSignature<Features, Section>> = <template>
  {{#let @row.original as |item|}}
    <UseSidebar as |sidebar|>
      <Drawer @direction={{if sidebar.isMobile "bottom" "right"}} as |d|>
        <Button @variant="link" class="w-fit px-0 text-left text-foreground" {{d.trigger}}>
          {{item.header}}
        </Button>
        <d.Content>
          <d.Header class="gap-1">
            <d.Title>{{item.header}}</d.Title>
            <d.Description>
              Showing total visitors for the last 6 months
            </d.Description>
          </d.Header>
          {{! Upstream's scrolling region takes no focus, so a keyboard can't scroll it;
              this one can (tabindex="0"), which the accessibility audit asks for. }}
          <div class="flex flex-col gap-4 overflow-y-auto px-4 text-sm" tabindex="0">
            {{#unless sidebar.isMobile}}
              <ChartContainer @config={{chartConfig}} as |chart|>
                <chart.AreaChart
                  @accessibilityLayer={{true}}
                  @data={{chartData}}
                  @margin={{chartMargin}}
                  as |a|
                >
                  <a.CartesianGrid @vertical={{false}} />
                  <a.XAxis
                    @dataKey="month"
                    @tickLine={{false}}
                    @axisLine={{false}}
                    @tickMargin={{8}}
                    @tickFormatter={{monthAbbr}}
                    @hide={{true}}
                  />
                  <a.ChartTooltip
                    @cursor={{false}}
                    @content={{component ChartTooltipContent indicator="dot"}}
                  />
                  <a.Area
                    @dataKey="mobile"
                    @type="natural"
                    @fill="var(--color-mobile)"
                    @fillOpacity={{0.6}}
                    @stroke="var(--color-mobile)"
                    @stackId="a"
                  />
                  <a.Area
                    @dataKey="desktop"
                    @type="natural"
                    @fill="var(--color-desktop)"
                    @fillOpacity={{0.4}}
                    @stroke="var(--color-desktop)"
                    @stackId="a"
                  />
                </chart.AreaChart>
              </ChartContainer>
              <Separator />
              <div class="grid gap-2">
                <div class="flex gap-2 leading-none font-medium">
                  Trending up by 5.2% this month
                  <Icon @icon={{TrendingUp}} class="size-4" />
                </div>
                <div class="text-muted-foreground">
                  Showing total visitors for the last 6 months. This is just some random text to
                  test the layout. It spans multiple lines and should wrap around.
                </div>
              </div>
              <Separator />
            {{/unless}}
            <form class="flex flex-col gap-4">
              <div class="flex flex-col gap-3">
                <Label for="header">Header</Label>
                <Input id="header" @defaultValue={{item.header}} />
              </div>
              <div class="grid grid-cols-2 gap-4">
                <div class="flex flex-col gap-3">
                  <Label for="type">Type</Label>
                  <Select @defaultValue={{item.type}} as |s|>
                    <s.Trigger id="type" class="w-full">
                      <s.Value @placeholder="Select a type" />
                    </s.Trigger>
                    <s.Content>
                      <s.Group>
                        <s.Item @value="Table of Contents">
                          Table of Contents
                        </s.Item>
                        <s.Item @value="Executive Summary">
                          Executive Summary
                        </s.Item>
                        <s.Item @value="Technical Approach">
                          Technical Approach
                        </s.Item>
                        <s.Item @value="Design">Design</s.Item>
                        <s.Item @value="Capabilities">Capabilities</s.Item>
                        <s.Item @value="Focus Documents">
                          Focus Documents
                        </s.Item>
                        <s.Item @value="Narrative">Narrative</s.Item>
                        <s.Item @value="Cover Page">Cover Page</s.Item>
                      </s.Group>
                    </s.Content>
                  </Select>
                </div>
                <div class="flex flex-col gap-3">
                  <Label for="status">Status</Label>
                  <Select @defaultValue={{item.status}} as |s|>
                    <s.Trigger id="status" class="w-full">
                      <s.Value @placeholder="Select a status" />
                    </s.Trigger>
                    <s.Content>
                      <s.Group>
                        <s.Item @value="Done">Done</s.Item>
                        <s.Item @value="In Progress">In Progress</s.Item>
                        <s.Item @value="Not Started">Not Started</s.Item>
                      </s.Group>
                    </s.Content>
                  </Select>
                </div>
              </div>
              <div class="grid grid-cols-2 gap-4">
                <div class="flex flex-col gap-3">
                  <Label for="target">Target</Label>
                  <Input id="target" @defaultValue={{item.target}} />
                </div>
                <div class="flex flex-col gap-3">
                  <Label for="limit">Limit</Label>
                  <Input id="limit" @defaultValue={{item.limit}} />
                </div>
              </div>
              <div class="flex flex-col gap-3">
                <Label for="reviewer">Reviewer</Label>
                <Select @defaultValue={{item.reviewer}} as |s|>
                  <s.Trigger id="reviewer" class="w-full">
                    <s.Value @placeholder="Select a reviewer" />
                  </s.Trigger>
                  <s.Content>
                    <s.Group>
                      <s.Item @value="Eddie Lake">Eddie Lake</s.Item>
                      <s.Item @value="Jamik Tashpulatov">
                        Jamik Tashpulatov
                      </s.Item>
                      <s.Item @value="Emily Whalen">Emily Whalen</s.Item>
                    </s.Group>
                  </s.Content>
                </Select>
              </div>
            </form>
          </div>
          <d.Footer>
            <Button>Submit</Button>
            <Button @variant="outline" {{d.close}}>Done</Button>
          </d.Footer>
        </d.Content>
      </Drawer>
    </UseSidebar>
  {{/let}}
</template>

const columns = columnHelper.columns([
  columnHelper.display({
    id: 'drag',
    header: flexComponent(DragHeader),
    cell: flexComponent(DragHandle),
  }),
  columnHelper.display({
    id: 'select',
    header: flexComponent(SelectAll),
    cell: flexComponent(SelectRow),
    enableSorting: false,
    enableHiding: false,
  }),
  columnHelper.accessor('header', {
    header: 'Header',
    cell: flexComponent(TableCellViewer),
    enableHiding: false,
  }),
  columnHelper.accessor('type', {
    header: 'Section Type',
    cell: flexComponent(TypeCell),
  }),
  columnHelper.accessor('status', {
    header: 'Status',
    cell: flexComponent(StatusCell),
  }),
  columnHelper.accessor('target', {
    header: flexComponent(TargetHeader),
    cell: flexComponent(TargetCell),
  }),
  columnHelper.accessor('limit', {
    header: flexComponent(LimitHeader),
    cell: flexComponent(LimitCell),
  }),
  columnHelper.accessor('reviewer', {
    header: 'Reviewer',
    cell: flexComponent(ReviewerCell),
  }),
  columnHelper.display({
    id: 'actions',
    header: flexComponent(ActionsHeader),
    cell: flexComponent(Actions),
  }),
])

/** upstream's arrayMove, from dnd-kit's sortable. */
function arrayMove<T>(array: T[], from: number, to: number): T[] {
  const next = array.slice()
  next.splice(to < 0 ? next.length + to : to, 0, next.splice(from, 1)[0]!)
  return next
}

const PAGE_SIZES = [10, 20, 30, 40, 50]

// DataTable (Joinery's, from @ember-joinery/data-table) marks each part for
// DataTableHarness (dt.head, dt.row, dt.viewOptions…) around upstream's Tabs; it renders
// `display: contents`, so the layout is upstream's.
export default class DataTable extends Component<{ Args: { data: Section[] } }> {
  // Upstream's useState(() => initialData): the rows as given, until a drag reorders them.
  @tracked reordered: Section[] | undefined

  get data(): Section[] {
    return this.reordered ?? this.args.data
  }

  rowSelection = tableState<RowSelectionState>({})
  columnVisibility = tableState<ColumnVisibilityState>({})
  columnFilters = tableState<ColumnFiltersState>([])
  sorting = tableState<SortingState>([])
  pagination = tableState({
    pageIndex: 0,
    pageSize: 10,
  })
  // What the handles' aria-describedby names: dnd-kit's DndDescribedBy-<id>, one per table.
  sortableId = idFor(this, 'dnd-describedby')

  get dataIds(): SortableId[] {
    return this.data.map(({ id }) => id)
  }

  handleDragEnd = (activeId: SortableId, overId: SortableId) => {
    const oldIndex = this.dataIds.indexOf(activeId)
    const newIndex = this.dataIds.indexOf(overId)
    this.reordered = arrayMove(this.data, oldIndex, newIndex)
  }

  sortable = new SortableRows({ instructionsId: this.sortableId, onMove: this.handleDragEnd })

  table = createTable(() => ({
    features,
    data: this.data,
    columns,
    state: {
      sorting: this.sorting.value,
      columnVisibility: this.columnVisibility.value,
      rowSelection: this.rowSelection.value,
      columnFilters: this.columnFilters.value,
      pagination: this.pagination.value,
    },
    getRowId: (row: Section) => row.id.toString(),
    enableRowSelection: true,
    onRowSelectionChange: this.rowSelection.set,
    onSortingChange: this.sorting.set,
    onColumnFiltersChange: this.columnFilters.set,
    onColumnVisibilityChange: this.columnVisibility.set,
    onPaginationChange: this.pagination.set,
    meta: { sortable: this.sortable },
  }))

  get hideableColumns() {
    return this.table
      .getAllColumns()
      .filter(column => typeof column.accessorFn !== 'undefined' && column.getCanHide())
  }

  get pageSize(): string {
    return `${this.table.state.pagination.pageSize}`
  }

  get pageNumber(): number {
    return this.table.state.pagination.pageIndex + 1
  }

  setPageSize = (value: string) => this.table.setPageSize(Number(value))
  firstPage = () => this.table.setPageIndex(0)
  lastPage = () => this.table.setPageIndex(this.table.getPageCount() - 1)
  pageSizes = PAGE_SIZES.map(String)
  columnCount = columns.length

  <template>
    <DataTableRoot @table={{this.table}} class="contents" as |dt|>
      <Tabs @defaultValue="outline" class="w-full flex-col justify-start gap-6" as |t|>
        <div class="flex items-center justify-between px-4 lg:px-6">
          <Label for="view-selector" class="sr-only">
            View
          </Label>
          <Select @defaultValue="outline" as |s|>
            <s.Trigger class="flex w-fit @4xl/main:hidden" @size="sm" id="view-selector">
              <s.Value @placeholder="Select a view" />
            </s.Trigger>
            <s.Content>
              <s.Group>
                <s.Item @value="outline">Outline</s.Item>
                <s.Item @value="past-performance">Past Performance</s.Item>
                <s.Item @value="key-personnel">Key Personnel</s.Item>
                <s.Item @value="focus-documents">Focus Documents</s.Item>
              </s.Group>
            </s.Content>
          </Select>
          <t.List
            class="hidden **:data-[slot=badge]:size-5 **:data-[slot=badge]:rounded-full **:data-[slot=badge]:bg-muted-foreground/30 **:data-[slot=badge]:px-1 @4xl/main:flex"
          >
            <t.Trigger @value="outline">Outline</t.Trigger>
            <t.Trigger @value="past-performance">
              Past Performance
              <Badge @variant="secondary">3</Badge>
            </t.Trigger>
            <t.Trigger @value="key-personnel">
              Key Personnel
              <Badge @variant="secondary">2</Badge>
            </t.Trigger>
            <t.Trigger @value="focus-documents">Focus Documents</t.Trigger>
          </t.List>
          <div class="flex items-center gap-2">
            <DropdownMenu {{dt.viewOptions}} as |m|>
              <Button @variant="outline" @size="sm" {{m.trigger}}>
                <Icon @icon={{Columns3}} data-icon="inline-start" />
                Columns
                <Icon @icon={{ChevronDown}} data-icon="inline-end" />
              </Button>
              <m.Content @align="end" class="w-32">
                {{#each this.hideableColumns key="id" as |column|}}
                  <m.CheckboxItem
                    class="capitalize"
                    @checked={{(column.getIsVisible)}}
                    @onCheckedChange={{column.toggleVisibility}}
                  >
                    {{column.id}}
                  </m.CheckboxItem>
                {{/each}}
              </m.Content>
            </DropdownMenu>
            {{! Below lg upstream's button shows its icon alone, with no name; aria-label names
                it at every width. }}
            <Button @variant="outline" @size="sm" aria-label="Add Section">
              <Icon @icon={{Plus}} />
              <span class="hidden lg:inline">Add Section</span>
            </Button>
          </div>
        </div>
        <t.Content @value="outline" class="relative flex flex-col gap-4 overflow-auto px-4 lg:px-6">
          <div class="overflow-hidden rounded-lg border">
            <Table as |tbl|>
              <tbl.Header class="sticky top-0 z-10 bg-muted">
                {{#each (this.table.getHeaderGroups) key="id" as |headerGroup|}}
                  <tbl.Row>
                    {{#each headerGroup.headers key="id" as |header|}}
                      <tbl.Head {{dt.head header}}>
                        {{#unless header.isPlaceholder}}
                          <this.table.FlexRender @header={{header}} />
                        {{/unless}}
                      </tbl.Head>
                    {{/each}}
                  </tbl.Row>
                {{/each}}
              </tbl.Header>
              <tbl.Body class="**:data-[slot=table-cell]:first:w-8">
                {{#let (this.table.getRowModel) as |rowModel|}}
                  {{#each rowModel.rows key="id" as |row|}}
                    <tbl.Row
                      data-state={{if (row.getIsSelected) "selected"}}
                      class="relative z-0 data-[dragging=true]:z-10 data-[dragging=true]:opacity-80"
                      {{dt.row row}}
                      {{this.sortable.row row.original.id}}
                    >
                      {{#each (row.getVisibleCells) key="id" as |cell|}}
                        <tbl.Cell>
                          <this.table.FlexRender @cell={{cell}} />
                        </tbl.Cell>
                      {{/each}}
                    </tbl.Row>
                  {{else}}
                    <tbl.Row>
                      <tbl.Cell colspan={{this.columnCount}} class="h-24 text-center">
                        No results.
                      </tbl.Cell>
                    </tbl.Row>
                  {{/each}}
                {{/let}}
              </tbl.Body>
            </Table>
            {{! What dnd-kit's DndContext renders for screen readers: the handles' instructions
                and a live region that says each step of a drag. }}
            <div id={{this.sortableId}} hidden>{{SORTABLE_INSTRUCTIONS}}</div>
            <div class="sr-only" role="status" aria-live="assertive" aria-atomic="true">
              {{this.sortable.announcement}}
            </div>
          </div>
          <div class="flex items-center justify-between px-4">
            <div class="hidden flex-1 text-sm text-muted-foreground lg:flex">
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
            <div class="flex w-full items-center gap-8 lg:w-fit">
              <div class="hidden items-center gap-2 lg:flex">
                <Label for="rows-per-page" class="text-sm font-medium">
                  Rows per page
                </Label>
                <Select @value={{this.pageSize}} @onValueChange={{this.setPageSize}} as |s|>
                  <s.Trigger @size="sm" class="w-20" id="rows-per-page">
                    <s.Value @placeholder={{this.pageSize}} />
                  </s.Trigger>
                  <s.Content @side="top">
                    <s.Group>
                      {{#each this.pageSizes as |pageSize|}}
                        <s.Item @value={{pageSize}}>
                          {{pageSize}}
                        </s.Item>
                      {{/each}}
                    </s.Group>
                  </s.Content>
                </Select>
              </div>
              <div class="flex w-fit items-center justify-center text-sm font-medium">
                Page
                {{this.pageNumber}}
                of
                {{(this.table.getPageCount)}}
              </div>
              <div class="ml-auto flex items-center gap-2 lg:ml-0">
                <Button
                  @variant="outline"
                  class="hidden h-8 w-8 p-0 lg:flex"
                  disabled={{not (this.table.getCanPreviousPage)}}
                  {{on "click" this.firstPage}}
                >
                  <span class="sr-only">Go to first page</span>
                  <Icon @icon={{ChevronsLeft}} />
                </Button>
                <Button
                  @variant="outline"
                  class="size-8"
                  @size="icon"
                  disabled={{not (this.table.getCanPreviousPage)}}
                  {{on "click" this.table.previousPage}}
                  {{dt.previousPage}}
                >
                  <span class="sr-only">Go to previous page</span>
                  <Icon @icon={{ChevronLeft}} />
                </Button>
                <Button
                  @variant="outline"
                  class="size-8"
                  @size="icon"
                  disabled={{not (this.table.getCanNextPage)}}
                  {{on "click" this.table.nextPage}}
                  {{dt.nextPage}}
                >
                  <span class="sr-only">Go to next page</span>
                  <Icon @icon={{ChevronRight}} />
                </Button>
                <Button
                  @variant="outline"
                  class="hidden size-8 lg:flex"
                  @size="icon"
                  disabled={{not (this.table.getCanNextPage)}}
                  {{on "click" this.lastPage}}
                >
                  <span class="sr-only">Go to last page</span>
                  <Icon @icon={{ChevronsRight}} />
                </Button>
              </div>
            </div>
          </div>
        </t.Content>
        <t.Content @value="past-performance" class="flex flex-col px-4 lg:px-6">
          <div class="aspect-video w-full flex-1 rounded-lg border border-dashed"></div>
        </t.Content>
        <t.Content @value="key-personnel" class="flex flex-col px-4 lg:px-6">
          <div class="aspect-video w-full flex-1 rounded-lg border border-dashed"></div>
        </t.Content>
        <t.Content @value="focus-documents" class="flex flex-col px-4 lg:px-6">
          <div class="aspect-video w-full flex-1 rounded-lg border border-dashed"></div>
        </t.Content>
      </Tabs>
    </DataTableRoot>
  </template>
}
