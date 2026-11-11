# Data Table

Powerful table and datagrids built using TanStack Table.

<Example @name="data-table-demo" @title="Data Table" @align="start" />

## Introduction

Every data table or datagrid I've created has been unique. They all behave differently, have
specific sorting and filtering requirements, and work with different data sources.

It doesn't make sense to combine all of these variations into a single component. If we do
that, we'll lose the flexibility that
[headless UI](https://tanstack.com/table/latest/docs/overview#what-is-headless-ui) provides.

So instead of a data-table component, I thought it would be more helpful to provide a guide on
how to build your own.

We'll start with the basic `<Table />` component and build a complex data table from scratch.

> **Tip:** If you find yourself using the same table in multiple places in your app, you can
> always extract it into a reusable component.

Joinery's `@ember-joinery/data-table` is the Ember half of that: TanStack Table's
framework-agnostic core, `@tanstack/table-core`, made reactive for Ember (`createTable()`, which
upstream's `useTable` is in React), `FlexRender` to render a column's header and cells, and
`DataTable`, the element around a table that its harness, `DataTableHarness`, drives. The rest
is Joinery's own components, as upstream's guide builds with shadcn's.

## Table of Contents

This guide will show you how to use [TanStack Table](https://tanstack.com/table) and the
`<Table />` component to build your own custom data table. We'll cover the following topics:

- [Set up Table Features](#set-up-table-features)
- [Basic Table](#basic-table)
- [Row Actions](#row-actions)
- [Pagination](#pagination)
- [Sorting](#sorting)
- [Filtering](#filtering)
- [Visibility](#visibility)
- [Row Selection](#row-selection)
- [Reusable Components](#reusable-components)

## Installation

1. The `<Table />` component comes with `@ember-joinery/ember`. Import Joinery's CSS once (see
   [Installation](/getting-started/installation.md)).

2. Add the data table add-on. It brings TanStack Table's core with it; this guide uses
   **TanStack Table v9**:

   ```bash
   pnpm add @ember-joinery/data-table @ember-joinery/ember
   ```

It ships no CSS of its own: a data table is made of Joinery's Table, Input, Checkbox, Button and
Dropdown Menu, which `joinery.css` styles. Everything `@tanstack/table-core` exports
(`tableFeatures`, the features and row models, `createColumnHelper`, the filter and sort
functions, their types) comes from `@ember-joinery/data-table` too, as upstream's examples import
it all from `@tanstack/react-table`.

## Prerequisites

We are going to build a table to show recent payments. Here's what our data looks like:

```ts
type Payment = {
  id: string
  amount: number
  status: 'pending' | 'processing' | 'success' | 'failed'
  email: string
}

export const payments: Payment[] = [
  {
    id: '728ed52f',
    amount: 100,
    status: 'pending',
    email: 'm@example.com',
  },
  {
    id: '489e1d42',
    amount: 125,
    status: 'processing',
    email: 'example@gmail.com',
  },
  // ...
]
```

## Project Structure

Start by creating the following file structure:

```text
app
├── components
│   └── payments
│       ├── columns.gts
│       ├── data-table-features.ts
│       └── data-table.gts
└── templates
    └── payments.gts
```

- `columns.gts` will contain our column definitions, and the components their cells render.
- `data-table-features.ts` will contain the shared `features` object that tells TanStack Table
  which behavior to enable.
- `data-table.gts` will contain our `<DataTable />` component.
- `templates/payments.gts` is where we'll render our table, with the data its route loads.

## Set up Table Features

TanStack Table v9 is feature-based: you opt into the behavior you want — sorting, filtering,
pagination, and so on — by declaring it with `tableFeatures()`. Anything you don't list is
tree-shaken out of your bundle. That includes the built-in filter and sort functions: register
the ones your columns rely on under `filterFns` and `sortFns` (our email filter uses
`includesString`, and string columns sort with `text` / `alphanumeric`).

```ts
// app/components/payments/data-table-features.ts
import {
  columnFilteringFeature,
  columnVisibilityFeature,
  createFilteredRowModel,
  createPaginatedRowModel,
  createSortedRowModel,
  filterFn_includesString,
  rowPaginationFeature,
  rowSelectionFeature,
  rowSortingFeature,
  sortFn_alphanumeric,
  sortFn_text,
  tableFeatures,
} from '@ember-joinery/data-table'

// New in v9: declare the features this table uses — anything you don't
// register is tree-shaken out of the bundle.
export const features = tableFeatures({
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

// Pass this as the first generic argument to `ColumnDef`, `Column`, `Table`,
// and `Row` so each type knows which feature APIs are available.
export type DataTableFeatures = typeof features
```

> **Note:** The core row model is always included, so you never register it yourself. Row
> models for optional features are created with `create*RowModel()` and registered on the
> features object — there are no more `get*RowModel` table options.

## Basic Table

Let's start by building a basic table.

### Column Definitions

First, we'll define our columns.

```ts
// app/components/payments/columns.gts
import { createColumnHelper } from '@ember-joinery/data-table'
import { type DataTableFeatures } from './data-table-features'

// This type is used to define the shape of our data.
export type Payment = {
  id: string
  amount: number
  status: 'pending' | 'processing' | 'success' | 'failed'
  email: string
}

// Use `accessor` for data columns and `display` for columns without one.
const columnHelper = createColumnHelper<DataTableFeatures, Payment>()

export const columns = columnHelper.columns([
  columnHelper.accessor('status', {
    header: 'Status',
  }),
  columnHelper.accessor('email', {
    header: 'Email',
  }),
  columnHelper.accessor('amount', {
    header: 'Amount',
  }),
])
```

> **Note:** Columns are where you define the core of what your table will look like. They
> define the data that will be displayed, how it will be formatted, sorted and filtered.

### `<DataTable />` component

Next, we'll create a `<DataTable />` component to render our table. `createTable()` makes the
table; give it a function, and it reads the options again whenever what the function reads
changes (here, `@data`).

```gts
// app/components/payments/data-table.gts
import Component from '@glimmer/component'
import { Table } from '@ember-joinery/ember'
import {
  DataTable as Root,
  createTable,
  type ColumnDef,
  type RowData,
} from '@ember-joinery/data-table'
import { features, type DataTableFeatures } from './data-table-features'

interface DataTableSignature<TData extends RowData> {
  Args: {
    columns: ColumnDef<DataTableFeatures, TData>[]
    data: TData[]
  }
}

export default class DataTable<TData extends RowData> extends Component<DataTableSignature<TData>> {
  table = createTable(() => ({
    features,
    data: this.args.data,
    columns: this.args.columns,
  }))

  <template>
    <Root @table={{this.table}} class="overflow-hidden rounded-md border" as |dt|>
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
                  <t.Cell><this.table.FlexRender @cell={{cell}} /></t.Cell>
                {{/each}}
              </t.Row>
            {{else}}
              <t.Row>
                <t.Cell colspan={{@columns.length}} class="h-24 text-center">
                  No results.
                </t.Cell>
              </t.Row>
            {{/each}}
          {{/let}}
        </t.Body>
      </Table>
    </Root>
  </template>
}
```

> **Tip:** If you find yourself using `<DataTable />` in multiple places, this is the component
> you could make reusable by extracting it to `app/components/data-table.gts`.
>
> `<DataTable @columns={{columns}} @data={{data}} />`

> **`<this.table.FlexRender />` vs `<FlexRender />`:** Every table `createTable()` makes carries
> `FlexRender` (`<this.table.FlexRender @header={{header}} />`, `@cell={{cell}}`), as v9's
> tables do, so a template that has the table needs no import of its own. The same component is
> exported as `FlexRender` for a template that renders outside the one that owns `table`.

Templates call the table's methods as helpers (`(this.table.getHeaderGroups)`), and the
methods of its rows, cells, columns and headers too (`(row.getIsSelected)`,
`(row.getVisibleCells)`): `createTable()` binds each one to its own object, which a template,
calling a function without the object it came from, needs. `dt.head` and `dt.row` mark the
header cells and rows for `DataTableHarness`, and `dt.head` gives each header cell its sort, in
`aria-sort`.

### Render the table

Finally, we'll render our table in our page template.

```gts
// app/templates/payments.gts
import DataTable from 'my-app/components/payments/data-table'
import { columns } from 'my-app/components/payments/columns'

<template>
  <div class="container mx-auto py-10">
    <DataTable @columns={{columns}} @data={{@model}} />
  </div>
</template>
```

## Cell Formatting

Let's format the amount cell to display the dollar amount. We'll also align the cell to the
right.

### Update columns definition

Update the `header` and `cell` definitions for amount as follows. A column's `header` or `cell`
can be a string, a function of its context, or a component: `flexComponent(Component)` passes
it the context's members as arguments (`@row`, `@column`, `@table`, `@getValue`…).

```gts
import { flexComponent, type CellComponentSignature } from '@ember-joinery/data-table'
import type { TOC } from '@ember/component/template-only'

const formatted = (amount: unknown) =>
  new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(parseFloat(String(amount)))

const AmountHeader = <template>
  <div class="text-right">Amount</div>
</template>

const AmountCell: TOC<CellComponentSignature<DataTableFeatures, Payment>> = <template>
  <div class="text-right font-medium">{{formatted (@row.getValue "amount")}}</div>
</template>

export const columns = columnHelper.columns([
  columnHelper.accessor('amount', {
    header: flexComponent(AmountHeader),
    cell: flexComponent(AmountCell),
  }),
])
```

You can use the same approach to format other cells and headers.

## Row Actions

Let's add row actions to our table. We'll use a `<DropdownMenu />` component for this.

### Update columns definition

Update our columns definition to add a new `actions` column. The `actions` cell renders a
`<DropdownMenu />` component.

```gts
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import { MoreHorizontal } from 'lucide'
import { Button, DropdownMenu, Icon } from '@ember-joinery/ember'

const copyPaymentId = (payment: Payment) => navigator.clipboard.writeText(payment.id)

const Actions: TOC<CellComponentSignature<DataTableFeatures, Payment>> = <template>
  {{#let @row.original as |payment|}}
    <DropdownMenu as |m|>
      <Button @variant="ghost" class="h-8 w-8 p-0" {{m.trigger}}>
        <span class="sr-only">Open menu</span>
        <Icon @icon={{MoreHorizontal}} class="h-4 w-4" />
      </Button>
      <m.Content @align="end">
        <m.Label>Actions</m.Label>
        <m.Item {{on "click" (fn copyPaymentId payment)}}>Copy payment ID</m.Item>
        <m.Separator />
        <m.Item>View customer</m.Item>
        <m.Item>View payment details</m.Item>
      </m.Content>
    </DropdownMenu>
  {{/let}}
</template>

export const columns = columnHelper.columns([
  // ...
  columnHelper.display({
    id: 'actions',
    cell: flexComponent(Actions),
  }),
  // ...
])
```

You can access the row data using `@row.original` in the cell's component. Use this to handle
actions for your row eg. use the `id` to make a DELETE call to your API.

## Pagination

Next, we'll add pagination to our table.

### Pagination is already enabled

Because our features object includes `rowPaginationFeature` and `createPaginatedRowModel()`, the
table automatically paginates rows into pages of 10 — there's nothing to add to
`createTable()`. See the
[pagination docs](https://tanstack.com/table/latest/docs/guide/pagination) for more
information on customizing page size and implementing manual pagination.

### Add pagination controls

We can add pagination controls to our table using the `<Button />` component and the
`table.previousPage()`, `table.nextPage()` API methods. `dt.previousPage` and `dt.nextPage`
mark them for the harness.

```gts
import { on } from '@ember/modifier'
import { Button } from '@ember-joinery/ember'

const not = (value: boolean) => !value

<template>
  <Root @table={{this.table}} as |dt|>
    <div class="overflow-hidden rounded-md border">
      <Table as |t|>{{! ... }}</Table>
    </div>
    <div class="flex items-center justify-end space-x-2 py-4">
      <Button
        @variant="outline"
        @size="sm"
        disabled={{not (this.table.getCanPreviousPage)}}
        {{on "click" this.table.previousPage}}
        {{dt.previousPage}}
      >
        Previous
      </Button>
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
  </Root>
</template>
```

See [Reusable Components](#reusable-components) section for a more advanced pagination
component.

## Sorting

Let's make the email column sortable.

The `rowSortingFeature` and sorted row model are already registered in our features object, so
all that's left is wiring up the sorting state.

### Update `<DataTable>`

The table keeps its own state, tracked, so this step is optional in Ember: a template that
reads the table re-renders when its sorting changes. To own the state yourself, as upstream
does with `React.useState`, keep it in a `tableState()`, and pass its `value` and `set`:

```gts
import { createTable, tableState, type SortingState } from '@ember-joinery/data-table'

export default class DataTable<TData extends RowData> extends Component<DataTableSignature<TData>> {
  sorting = tableState<SortingState>([])

  table = createTable(() => ({
    features,
    data: this.args.data,
    columns: this.args.columns,
    onSortingChange: this.sorting.set,
    state: {
      sorting: this.sorting.value,
    },
  }))

  // ...
}
```

### Make header cell sortable

We can now update the `email` header cell to add sorting controls.

```gts
import { ArrowUpDown } from 'lucide'
import type { HeaderComponentSignature, Column } from '@ember-joinery/data-table'

const toggleSorting = (column: Column<DataTableFeatures, Payment>) =>
  column.toggleSorting(column.getIsSorted() === 'asc')

const EmailHeader: TOC<HeaderComponentSignature<DataTableFeatures, Payment>> = <template>
  <Button @variant="ghost" {{on "click" (fn toggleSorting @column)}}>
    Email
    <Icon @icon={{ArrowUpDown}} class="ml-2 h-4 w-4" />
  </Button>
</template>

export const columns = columnHelper.columns([
  columnHelper.accessor('email', {
    header: flexComponent(EmailHeader),
  }),
])
```

This will automatically sort the table (asc and desc) when the user toggles on the header cell.
`dt.head` puts the column's sort on its header cell, in `aria-sort`.

## Filtering

Let's add a search input to filter emails in our table.

The `columnFilteringFeature` and filtered row model are already part of our features object, so
we only need to wire up the filter state and render an input.

### Update `<DataTable>`

```gts
import { Input } from '@ember-joinery/ember'
import { type ColumnFiltersState } from '@ember-joinery/data-table'

export default class DataTable<TData extends RowData> extends Component<DataTableSignature<TData>> {
  sorting = tableState<SortingState>([])
  columnFilters = tableState<ColumnFiltersState>([])

  table = createTable(() => ({
    features,
    data: this.args.data,
    columns: this.args.columns,
    onSortingChange: this.sorting.set,
    onColumnFiltersChange: this.columnFilters.set,
    state: {
      sorting: this.sorting.value,
      columnFilters: this.columnFilters.value,
    },
  }))

  get emailFilter(): string {
    return (this.table.getColumn('email')?.getFilterValue() as string) ?? ''
  }

  filterEmails = (value: string) => this.table.getColumn('email')?.setFilterValue(value)

  <template>
    <Root @table={{this.table}} as |dt|>
      <div class="flex items-center py-4">
        <Input
          placeholder="Filter emails..."
          @value={{this.emailFilter}}
          @onValueChange={{this.filterEmails}}
          class="max-w-sm"
          {{dt.filter "email"}}
        />
      </div>
      <div class="overflow-hidden rounded-md border">
        <Table as |t|>{{! ... }}</Table>
      </div>
    </Root>
  </template>
}
```

Filtering is now enabled for the `email` column. You can add filters to other columns as well.
See the [filtering docs](https://tanstack.com/table/latest/docs/guide/column-filtering) for more
information on customizing filters. A filter that changes the rows goes back to the first
page, as TanStack's does, once the render that saw it is over.

## Visibility

Adding column visibility is fairly simple using TanStack Table's visibility API.

### Update `<DataTable>`

```gts
import { DropdownMenu } from '@ember-joinery/ember'
import { type ColumnVisibilityState } from '@ember-joinery/data-table'

export default class DataTable<TData extends RowData> extends Component<DataTableSignature<TData>> {
  // ...
  columnVisibility = tableState<ColumnVisibilityState>({})

  table = createTable(() => ({
    // ...
    onColumnVisibilityChange: this.columnVisibility.set,
    state: {
      // ...
      columnVisibility: this.columnVisibility.value,
    },
  }))

  get hideableColumns() {
    return this.table.getAllColumns().filter(column => column.getCanHide())
  }

  <template>
    <Root @table={{this.table}} as |dt|>
      <div class="flex items-center py-4">
        <Input
          placeholder="Filter emails..."
          {{! ... }}
        />
        <DropdownMenu {{dt.viewOptions}} as |m|>
          <Button @variant="outline" class="ml-auto" {{m.trigger}}>Columns</Button>
          <m.Content @align="end">
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
      </div>
      <div class="overflow-hidden rounded-md border">
        <Table as |t|>{{! ... }}</Table>
      </div>
    </Root>
  </template>
}
```

This adds a dropdown menu that you can use to toggle column visibility.

## Row Selection

Next, we're going to add row selection to our table.

### Update column definitions

```gts
import { Checkbox } from '@ember-joinery/ember'
import type { CheckedState } from '@ember-joinery/primitives/checkbox'
import type { Row, Table } from '@ember-joinery/data-table'

const pageSelection = (table: Table<DataTableFeatures, Payment>): CheckedState =>
  table.getIsAllPageRowsSelected() || (table.getIsSomePageRowsSelected() && 'indeterminate')
const toggleAllPageRows = (table: Table<DataTableFeatures, Payment>, value: CheckedState) =>
  table.toggleAllPageRowsSelected(!!value)
const toggleRow = (row: Row<DataTableFeatures, Payment>, value: CheckedState) =>
  row.toggleSelected(!!value)

const SelectAll: TOC<HeaderComponentSignature<DataTableFeatures, Payment>> = <template>
  <Checkbox
    @checked={{pageSelection @table}}
    @onCheckedChange={{fn toggleAllPageRows @table}}
    aria-label="Select all"
  />
</template>

const SelectRow: TOC<CellComponentSignature<DataTableFeatures, Payment>> = <template>
  <Checkbox
    @checked={{(@row.getIsSelected)}}
    @onCheckedChange={{fn toggleRow @row}}
    aria-label="Select row"
  />
</template>

export const columns = columnHelper.columns([
  columnHelper.display({
    id: 'select',
    header: flexComponent(SelectAll),
    cell: flexComponent(SelectRow),
    enableSorting: false,
    enableHiding: false,
  }),
])
```

### Update `<DataTable>`

```ts
import { type RowSelectionState } from '@ember-joinery/data-table'

export default class DataTable<TData extends RowData> extends Component<DataTableSignature<TData>> {
  sorting = tableState<SortingState>([])
  columnFilters = tableState<ColumnFiltersState>([])
  columnVisibility = tableState<ColumnVisibilityState>({})
  rowSelection = tableState<RowSelectionState>({})

  table = createTable(() => ({
    features,
    data: this.args.data,
    columns: this.args.columns,
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
}
```

This adds a checkbox to each row and a checkbox in the header to select all rows.

### Show selected rows

You can show the number of selected rows using the `table.getFilteredSelectedRowModel()` API.

```gts
<div class="flex-1 text-sm text-muted-foreground">
  {{#let
    (this.table.getFilteredSelectedRowModel) (this.table.getFilteredRowModel)
    as |selected filtered|
  }}
    {{selected.rows.length}} of {{filtered.rows.length}} row(s) selected.
  {{/let}}
</div>
```

## Reusable Components

Here are some components you can use to build your data tables. Upstream's come from its
[Tasks](https://ui.shadcn.com/examples/tasks) demo; these are their Ember ports, each taking the
table, or a column, as an argument.

### Column header

Make any column header sortable and hideable.

```gts
// app/components/data-table-column-header.gts
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import { ArrowDown, ArrowUp, ChevronsUpDown, EyeOff } from 'lucide'
import { Button, DropdownMenu, Icon } from '@ember-joinery/ember'
import type { Column } from '@ember-joinery/data-table'

const iconFor = (sorted: false | 'asc' | 'desc') =>
  sorted === 'desc' ? ArrowDown : sorted === 'asc' ? ArrowUp : ChevronsUpDown
const sort = (column: Column<DataTableFeatures, unknown>, desc: boolean) =>
  column.toggleSorting(desc)
const hide = (column: Column<DataTableFeatures, unknown>) => column.toggleVisibility(false)

<template>
  {{#if (@column.getCanSort)}}
    <div class="flex items-center gap-2" ...attributes>
      <DropdownMenu as |m|>
        <Button
          @variant="ghost"
          @size="sm"
          class="-ml-3 h-8 data-[state=open]:bg-accent"
          {{m.trigger}}
        >
          <span>{{@title}}</span>
          <Icon @icon={{iconFor (@column.getIsSorted)}} />
        </Button>
        <m.Content @align="start">
          <m.Item {{on "click" (fn sort @column false)}}><Icon @icon={{ArrowUp}} />Asc</m.Item>
          <m.Item {{on "click" (fn sort @column true)}}><Icon @icon={{ArrowDown}} />Desc</m.Item>
          <m.Separator />
          <m.Item {{on "click" (fn hide @column)}}><Icon @icon={{EyeOff}} />Hide</m.Item>
        </m.Content>
      </DropdownMenu>
    </div>
  {{else}}
    <div ...attributes>{{@title}}</div>
  {{/if}}
</template>
```

```gts
const EmailHeader = <template>
  <DataTableColumnHeader @column={{@column}} @title="Email" />
</template>

export const columns = columnHelper.columns([
  columnHelper.accessor('email', {
    header: flexComponent(EmailHeader),
  }),
])
```

### Pagination

Add pagination controls to your table including page size and selection count.

```gts
// app/components/data-table-pagination.gts
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight } from 'lucide'
import { Button, Icon, Select } from '@ember-joinery/ember'

const PAGE_SIZES = ['10', '20', '25', '30', '40', '50']
const not = (value: boolean) => !value
const plusOne = (value: number) => value + 1
const minusOne = (value: number) => value - 1
const setPageSize = (table: Table<DataTableFeatures, unknown>, value: string) =>
  table.setPageSize(Number(value))

<template>
  <div class="flex items-center justify-between px-2">
    <div class="flex-1 text-sm text-muted-foreground">
      {{#let (@table.getFilteredSelectedRowModel) (@table.getFilteredRowModel) as |s f|}}
        {{s.rows.length}}
        of
        {{f.rows.length}}
        row(s) selected.
      {{/let}}
    </div>
    <div class="flex items-center space-x-6 lg:space-x-8">
      <div class="flex items-center space-x-2">
        <p class="text-sm font-medium">Rows per page</p>
        <Select
          @value="{{@table.state.pagination.pageSize}}"
          @onValueChange={{fn setPageSize @table}}
          as |s|
        >
          <s.Trigger class="h-8 w-[70px]" aria-label="Rows per page"><s.Value /></s.Trigger>
          <s.Content @side="top">
            {{#each PAGE_SIZES as |pageSize|}}
              <s.Item @value={{pageSize}}>{{pageSize}}</s.Item>
            {{/each}}
          </s.Content>
        </Select>
      </div>
      <div class="flex w-[100px] items-center justify-center text-sm font-medium">
        Page
        {{plusOne @table.state.pagination.pageIndex}}
        of
        {{(@table.getPageCount)}}
      </div>
      <div class="flex items-center space-x-2">
        <Button
          @variant="outline"
          @size="icon"
          class="hidden size-8 lg:flex"
          disabled={{not (@table.getCanPreviousPage)}}
          {{on "click" (fn @table.setPageIndex 0)}}
        >
          <span class="sr-only">Go to first page</span>
          <Icon @icon={{ChevronsLeft}} />
        </Button>
        <Button
          @variant="outline"
          @size="icon"
          class="size-8"
          disabled={{not (@table.getCanPreviousPage)}}
          {{on "click" @table.previousPage}}
        >
          <span class="sr-only">Go to previous page</span>
          <Icon @icon={{ChevronLeft}} />
        </Button>
        <Button
          @variant="outline"
          @size="icon"
          class="size-8"
          disabled={{not (@table.getCanNextPage)}}
          {{on "click" @table.nextPage}}
        >
          <span class="sr-only">Go to next page</span>
          <Icon @icon={{ChevronRight}} />
        </Button>
        <Button
          @variant="outline"
          @size="icon"
          class="hidden size-8 lg:flex"
          disabled={{not (@table.getCanNextPage)}}
          {{on "click" (fn @table.setPageIndex (minusOne (@table.getPageCount)))}}
        >
          <span class="sr-only">Go to last page</span>
          <Icon @icon={{ChevronsRight}} />
        </Button>
      </div>
    </div>
  </div>
</template>
```

```gts
<DataTablePagination @table={{this.table}} />
```

### Column toggle

A component to toggle column visibility.

```gts
// app/components/data-table-view-options.gts
import { Settings2 } from 'lucide'
import { Button, DropdownMenu, Icon } from '@ember-joinery/ember'

const toggleable = (table: Table<DataTableFeatures, unknown>) =>
  table
    .getAllColumns()
    .filter(column => typeof column.accessorFn !== 'undefined' && column.getCanHide())

<template>
  <DropdownMenu as |m|>
    <Button @variant="outline" @size="sm" class="ml-auto hidden h-8 lg:flex" {{m.trigger}}>
      <Icon @icon={{Settings2}} />
      View
    </Button>
    <m.Content @align="end" class="w-[150px]">
      <m.Label>Toggle columns</m.Label>
      <m.Separator />
      {{#each (toggleable @table) key="id" as |column|}}
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
</template>
```

```gts
<DataTableViewOptions @table={{this.table}} />
```

These three are recipes, as upstream's are: they aren't in the package, so copy them into your
app and change them as you like. Give the pagination's buttons `{{dt.previousPage}}` and
`{{dt.nextPage}}`, and the view options' menu `{{dt.viewOptions}}`, for `DataTableHarness` to
find them.

## RTL

Joinery's styles use logical properties, so a data table lays itself out right to left inside
any element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the first column is
on the right, and the controls around the table, which take their direction from the nearest
`dir`, start there too. Upstream's example uses `gap-2`, `ms-auto` and `text-start` for its own
layout, which flip with it.

<Example @name="data-table-rtl" @title="RTL" @dir="rtl" @align="start" />

## API Reference

### `createTable(options)`

Makes a TanStack table that Ember tracks, as upstream's `useTable` does in React: table-core's
`constructTable()` with reactivity bindings on Ember's autotracking (`emberReactivity()`). A
template or getter that reads the table (a row model, a column's sort, `table.state`)
re-renders when what it read changes, and nothing else does.

| Argument  | Type                                   | What it is                                                                                                               |
| --------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `options` | `TableOptions` or `() => TableOptions` | table-core's options. Given a function, it reads them again when what the function read changes. `features` is read once |

It returns table-core's table (`EmberTable<TFeatures, TData>`), with:

| Member          | What it is                                                                            |
| --------------- | ------------------------------------------------------------------------------------- |
| `FlexRender`    | `FlexRender`, so a template with the table needs no import: `<this.table.FlexRender>` |
| `state`         | The table's whole state (`table.store.state`), tracked                                |
| `setOptions()`  | table-core's: what it changes stays on top of what the options function gives         |
| everything else | table-core's API; row, cell, column and header methods come bound to their object     |

Without `state`, the table keeps its own (from `initialState`, and its `reset*()` go back to
it). With a slice in `state` and its `on<Slice>Change`, you own that slice.

### `emberReactivity()`

TanStack Table v9 leaves reactivity to its adapters, through a table's `coreReactivityFeature`.
`emberReactivity()` is Ember's: the table's state in tracked atoms, derived values computed
where they are read (so autotracking follows them), and the resets table-core puts off until
after a render run then, with `settled()` waiting for them. `createTable()` uses it; pass it
yourself to table-core's `constructTable()` for a table without the rest:

```ts
import { constructTable, emberReactivity, tableFeatures } from '@ember-joinery/data-table'

const features = tableFeatures({
  coreReactivityFeature: emberReactivity(),
  rowSortingFeature,
  sortedRowModel: createSortedRowModel(),
})

const table = constructTable({ features, data, columns })
```

Such a table reads plain options, so it doesn't follow changes to them, and its rows' methods
aren't bound for templates.

### `tableState(initial)`

A tracked slice of table state you own, upstream's `React.useState` for a table: `value` is the
slice, and `set` takes a value or an updater, as `on<Slice>Change` hands it either. `set` is
bound, so pass it as it is: `onSortingChange: this.sorting.set`.

### `FlexRender`

| Argument  | Type     | What it renders                                                    |
| --------- | -------- | ------------------------------------------------------------------ |
| `@header` | `Header` | Its column's `header`, with the header's context                   |
| `@cell`   | `Cell`   | Its column's `cell` (or `aggregatedCell`), with the cell's context |
| `@footer` | `Header` | Its column's `footer`, with the header's context                   |

A column's template may be a string, a function of the context (a string or number is rendered
as text; `null`, `undefined` and booleans as nothing), or a component. A component gets
`@context` and each of its members: `@table`, `@column`, `@header` for a header, and `@row`,
`@cell`, `@getValue`, `@renderValue` for a cell. `flexComponent(Component)` puts a component in
a column definition (table-core's types take strings and functions there); type the component
with `CellComponentSignature<TFeatures, TData, TValue?>` or `HeaderComponentSignature<…>`.

### `DataTable`

| Argument | Type      | Default | What it is                       |
| -------- | --------- | ------- | -------------------------------- |
| `@table` | `Table`   |         | The table, from `createTable()`  |
| `@name`  | `string`  |         | Its name, for `DataTableHarness` |
| `@as`    | `TagName` | `div`   | The tag to render                |

It renders an element of its own, with no style, around what you put in it, and yields:

| Yield             | Goes on                          | What it does                                                                                          |
| ----------------- | -------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `dt.table`        |                                  | The table it was given                                                                                |
| `dt.FlexRender`   |                                  | `FlexRender`                                                                                          |
| `dt.head header`  | each header cell (`t.Head`)      | Its sort in `aria-sort` (on the column sorted first), `colspan` over grouped columns, the column's id |
| `dt.row row`      | each body row (`t.Row`)          | The row's id                                                                                          |
| `dt.filter id`    | a filter input                   | The column it filters                                                                                 |
| `dt.previousPage` | the previous page button         | Marks it                                                                                              |
| `dt.nextPage`     | the next page button             | Marks it                                                                                              |
| `dt.viewOptions`  | the column menu (`DropdownMenu`) | Marks it                                                                                              |

Each marks its element for `DataTableHarness`, which is all they do but for `dt.head`'s ARIA.

### Data attributes

| Element        | Attribute            | Value                                                                   |
| -------------- | -------------------- | ----------------------------------------------------------------------- |
| `DataTable`    | `data-test-jn`       | `data-table`                                                            |
|                | `data-test-jn-name`  | its `@name`                                                             |
|                | `id`                 | its own, unless you give one                                            |
| each part      | `data-test-jn-part`  | `head`, `row`, `filter`, `previous-page`, `next-page` or `view-options` |
|                | `data-test-jn-value` | the column's id (`head`, `filter`) or the row's (`row`)                 |
|                | `data-test-jn-owner` | the `DataTable`'s `id`                                                  |
| a header cell  | `aria-sort`          | `ascending` or `descending`, on the column sorted first                 |
| a selected row | `data-state`         | `selected`, as you set it (`{{if (row.getIsSelected) "selected"}}`)     |

## Keyboard interactions

A data table is a table, not a grid: the keyboard reaches its controls, each a native one.

| Key              | What it does                                                                                                                       |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `Tab`            | Moves through the filter, the column menu, the header's buttons and checkboxes, each row's, and the page buttons, in reading order |
| `Space`          | On a checkbox, selects or deselects its row (or, in the header, the page)                                                          |
| `Enter`, `Space` | On a sort button, sorts by its column; on a page button, turns the page                                                            |
| `ArrowDown`, …   | In the column menu, as in every Dropdown Menu                                                                                      |

Rows keep their elements as they sort and filter (each is keyed by its id), so focus stays on a
row's checkbox or a sort button that re-renders.

## Accessibility

- A sortable column's header cell says how its rows are sorted, in `aria-sort` (`dt.head`), as
  the [APG's sortable table](https://www.w3.org/WAI/ARIA/apg/patterns/table/examples/sortable-table/)
  does; upstream's say nothing, and a screen reader only hears the sort button's name. It goes on
  the column sorted first, as ARIA asks for one at a time.
- The checkboxes are named (`Select all`, `Select row`), and the header's is `mixed` while some
  rows of the page are selected.
- Upstream's actions column has no header; the examples give it a visually hidden one
  (`Actions`), since every header cell needs a name (axe's `empty-table-header`). Its trigger is
  named by its hidden `Open menu`.
- The filter is named by its placeholder, as upstream's is; a visible label names it better.

## Testing

`DataTableHarness` from `@ember-joinery/data-table/test-support` drives the parts inside a
`DataTable`: it reads the rows and columns shown, each column's sort (from `aria-sort`), and
which rows are selected (from their checkboxes), and works the table as a user does:

```ts
import { DataTableHarness } from '@ember-joinery/data-table/test-support'

const payments = new DataTableHarness('payments') // <DataTable @name="payments">
await payments.filter('ken')
assert.deepEqual(payments.column('email'), ['ken99@example.com'])
await payments.sort('email')
assert.strictEqual(payments.sortOf('email'), 'ascending')
await payments.toggleRow(0)
assert.deepEqual(payments.selectedRows, [0])
await payments.toggleColumn('status')
assert.false(payments.isColumnShown('status'))
```

A column is its id, its header's text, or its position among those shown.

| Member                                      | What it is                                                          |
| ------------------------------------------- | ------------------------------------------------------------------- |
| `table`                                     | The `TableHarness` inside                                           |
| `columns`, `columnIds`, `columnHeads`       | The columns shown: their headers' text, their ids, their cells      |
| `head(column)`, `isColumnShown(id)`         | A column's header cell; whether it is shown                         |
| `rows`, `rowIds`, `rowElements`, `rowCount` | The rows shown (this page): their cells' text, ids, elements, count |
| `row(index)`, `cell(index, column)`         | A row; a row's cell in a column                                     |
| `column(column)`                            | The text of every row's cell in a column                            |
| `isEmpty`, `emptyText`                      | Whether no rows show, and what the body says then (`No results.`)   |
| `sortOf(column)`, `sortedBy`                | `ascending`, `descending` or `none`; the column sorted first        |
| `sortButton(column)`, `sort(column)`        | The button in a column's header, and a click on it                  |
| `filterInput(id?)`, `filterValue(id?)`      | A filter, and what it holds                                         |
| `filter(value, id?)`                        | Types into a filter                                                 |
| `canPreviousPage`, `canNextPage`            | Whether each page button can be used                                |
| `previousPage()`, `nextPage()`              | Clicks a page button                                                |
| `rowCheckbox(index)`, `selectAll`           | A row's checkbox, and the header's (`CheckboxHarness`es)            |
| `isSelected(index)`, `selectedRows`         | Whether a row is selected; the selected rows' indexes               |
| `toggleRow(index)`, `toggleAll()`           | Clicks a row's checkbox, or the header's                            |
| `viewOptions`                               | The column menu, a `DropdownMenuHarness`                            |
| `columnOptions()`, `toggleColumn(label)`    | The columns it offers; toggles one                                  |

`settled()` waits for what a table puts off until after a render (going back to the first page
when a filter changes the rows), so every action leaves the table where it ends up. Each
example's Test tab has a whole test.

## Upstream

shadcn/ui's [Data Table](https://ui.shadcn.com/docs/components/radix/data-table), from
`apps/v4/content/docs/components/radix/data-table.mdx` and its examples at shadcn-ui/ui@8ab2771,
in the Nova style, on [TanStack Table](https://tanstack.com/table) v9's
`@tanstack/table-core` (9.3.1), which upstream reaches through `@tanstack/react-table`.
