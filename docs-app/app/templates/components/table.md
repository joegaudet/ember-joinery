# Table

A responsive table component.

<Example @name="table-demo" @title="Table" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Table } from '@ember-joinery/ember'
```

## Usage

```gts
<Table as |t|>
  <t.Caption>A list of your recent invoices.</t.Caption>
  <t.Header>
    <t.Row>
      <t.Head class="w-[100px]">Invoice</t.Head>
      <t.Head>Status</t.Head>
      <t.Head>Method</t.Head>
      <t.Head class="text-right">Amount</t.Head>
    </t.Row>
  </t.Header>
  <t.Body>
    <t.Row>
      <t.Cell class="font-medium">INV001</t.Cell>
      <t.Cell>Paid</t.Cell>
      <t.Cell>Credit Card</t.Cell>
      <t.Cell class="text-right">$250.00</t.Cell>
    </t.Row>
  </t.Body>
</Table>
```

Each part is the native element (`<t.Row>` is a `tr`, `<t.Cell>` a `td`), so `colspan`, `scope`
and listeners go on it as attributes.

## Composition

Use the following composition to build a `Table`:

```text
Table
├── t.Caption
├── t.Header
│   └── t.Row
│       ├── t.Head
│       ├── t.Head
│       ├── t.Head
│       └── t.Head
├── t.Body
│   ├── t.Row
│   │   ├── t.Cell
│   │   ├── t.Cell
│   │   ├── t.Cell
│   │   └── t.Cell
│   └── t.Row
│       ├── t.Cell
│       ├── t.Cell
│       ├── t.Cell
│       └── t.Cell
└── t.Footer
```

## Footer

Use `<t.Footer>` to add a footer to the table.

<Example @name="table-footer" @title="Footer" />

## Actions

A table showing actions for each row using a [`<DropdownMenu />`](/components/dropdown-menu.md)
component.

<Example @name="table-actions" @title="Actions" />

## Data Table

You can use the `<Table />` component to build more complex data tables. Combine it with
[TanStack Table](https://tanstack.com/table/latest) to create tables with sorting, filtering and
pagination. Joinery's Data Table, on `@tanstack/table-core`, comes in its own package,
`@ember-joinery/data-table`, which hasn't landed yet.

## RTL

Joinery's styles use logical properties, so a table lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the first column is on the
right, and a header cell's text starts there.

<Example @name="table-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Table

| Argument | Type     | Default | What it does                                       |
| -------- | -------- | ------- | -------------------------------------------------- |
| `@name`  | `string` |         | Its name, for `TableHarness` (`data-test-jn-name`) |

It renders a `<table>` inside a `div` that scrolls it sideways when it is too wide for its
place, and takes attributes on the table. While the table is wider than its container and has
nothing inside that takes focus, the container joins the tab order (`tabindex="0"`), so the
keyboard can scroll it.

It yields its parts, each a component and a modifier for an element of your own
(`<tr {{t.row}}>`):

| Part        | Modifier    | Element   | `data-slot`     |
| ----------- | ----------- | --------- | --------------- |
| `t.Caption` | `t.caption` | `caption` | `table-caption` |
| `t.Header`  | `t.header`  | `thead`   | `table-header`  |
| `t.Body`    | `t.body`    | `tbody`   | `table-body`    |
| `t.Footer`  | `t.footer`  | `tfoot`   | `table-footer`  |
| `t.Row`     | `t.row`     | `tr`      | `table-row`     |
| `t.Head`    | `t.head`    | `th`      | `table-head`    |
| `t.Cell`    | `t.cell`    | `td`      | `table-cell`    |

Each part takes `@as`, a tag to render instead, such as `<t.Cell @as="th" scope="row">` for a
cell that heads its row.

### Data attributes

| Attribute           | On             | Value                                         |
| ------------------- | -------------- | --------------------------------------------- |
| `class`             | the container  | `jn-table-container`                          |
| `class`             | the table      | `jn-table`                                    |
| `class`             | each part      | `jn-<data-slot>`, as `jn-table-row`           |
| `data-slot`         | each           | `table-container`, `table`, and the part's    |
| `data-state`        | a row of yours | `selected` shades it, as Radix's rows do      |
| `data-test-jn`      | the table      | `table`                                       |
| `data-test-jn-name` | the table      | its `@name`                                   |
| `data-test-jn-part` | each part      | `caption`, `header`, `body`, `footer`, `row`… |

A row shades on hover, with `data-state="selected"`, and while something in it is expanded
(`aria-expanded="true"`), as upstream's.

## Keyboard interactions

A table has no keyboard interactions of its own: `Tab` moves through the links, buttons and
fields in its cells. When the table scrolls sideways and has none, `Tab` stops on its container,
and the arrow keys scroll it.

## Accessibility

- It is a native `<table>`, so screen readers announce its rows and columns, and read each cell
  with its column's header. Put the header cells in `<t.Header>`, and give a cell that heads its
  row `@as="th"` and `scope="row"`.
- `<t.Caption>` names the table. Without one, give the table `aria-label` or
  `aria-labelledby`.
- A table wider than its place scrolls in its container, which the keyboard can reach (see
  above).

## Testing

`TableHarness` from `@ember-joinery/test-support` reads a `<Table>` through its native
structure:

```ts
import { TableHarness } from '@ember-joinery/test-support'

const invoices = new TableHarness('invoices') // <Table @name="invoices">
assert.deepEqual(invoices.columns, ['Invoice', 'Status', 'Method', 'Amount'])
assert.deepEqual(invoices.column('Status'), ['Paid', 'Pending', 'Unpaid'])
assert.dom(invoices.cell(0, 'Amount')).hasText('$250.00')
```

| Member                | What it is                                                      |
| --------------------- | --------------------------------------------------------------- |
| `table`               | The `<table>`                                                   |
| `container`           | The element that scrolls it                                     |
| `caption`             | The caption's text, or `null`                                   |
| `columns`             | The header's cells' text: the columns' names                    |
| `rows`                | Each body row's cells' text                                     |
| `rowElements`         | The body's rows                                                 |
| `rowCount`            | How many rows the body has                                      |
| `footer`              | Each footer row's cells' text                                   |
| `row(index)`          | The body's row at `index`                                       |
| `cell(index, column)` | A body row's cell, in a column given by position or by its name |
| `column(column)`      | Every body row's cell's text in a column, by position or name   |

## Upstream

shadcn/ui's [Table](https://ui.shadcn.com/docs/components/radix/table), from
`apps/v4/registry/bases/radix/ui/table.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
