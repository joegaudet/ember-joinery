# @ember-joinery/data-table

shadcn/ui's [Data Table](https://ui.shadcn.com/docs/components/radix/data-table) for Ember, an
opt-in add-on to [Joinery](https://joegaudet.com/ember-joinery/): sorting, filtering,
pagination, row selection and column visibility, on [TanStack Table](https://tanstack.com/table)
v9's framework-agnostic core, `@tanstack/table-core`.

> **Pre-release.** Nothing is published yet; see the
> [repository](https://github.com/joegaudet/ember-joinery#readme).

```bash
npm install @ember-joinery/data-table @ember-joinery/ember
```

As upstream's page is a guide to building your own data table, this is what you build one with
in Ember:

- `createTable()`, upstream's `useTable`: a TanStack table whose state Ember tracks, so a
  template that reads it re-renders when what it read changes. Its rows', cells', columns' and
  headers' methods come bound, so templates can call them (`{{(row.getIsSelected)}}`).
- `tableState()`, upstream's `React.useState` for a slice of table state you own.
- `FlexRender` (and `table.FlexRender`), which renders a column's header or cell: a string, a
  function of its context, or a component (`flexComponent(StatusCell)`).
- `DataTable`, the element around a table, whose modifiers mark its parts for the harness and
  give its header cells `aria-sort`.
- Everything `@tanstack/table-core` exports, so a table imports from one place.

It ships no CSS of its own: Joinery's Table, Input, Checkbox, Button and Dropdown Menu, which
`@ember-joinery/ember`'s `joinery.css` styles, make up the table.

```gts
import Component from '@glimmer/component'
import { Table } from '@ember-joinery/ember'
import {
  DataTable,
  createSortedRowModel,
  createTable,
  rowSortingFeature,
  tableFeatures,
} from '@ember-joinery/data-table'

const features = tableFeatures({ rowSortingFeature, sortedRowModel: createSortedRowModel() })

export default class Payments extends Component {
  table = createTable(() => ({ features, columns, data: this.args.payments }))

  <template>
    <DataTable @table={{this.table}} @name="payments" as |dt|>
      <Table as |t|>
        <t.Header>
          {{#each (this.table.getHeaderGroups) as |group|}}
            <t.Row>
              {{#each group.headers as |header|}}
                <t.Head {{dt.head header}}><dt.FlexRender @header={{header}} /></t.Head>
              {{/each}}
            </t.Row>
          {{/each}}
        </t.Header>
        <t.Body>
          {{#let (this.table.getRowModel) as |model|}}
            {{#each model.rows key="id" as |row|}}
              <t.Row {{dt.row row}}>
                {{#each (row.getAllCells) as |cell|}}
                  <t.Cell><dt.FlexRender @cell={{cell}} /></t.Cell>
                {{/each}}
              </t.Row>
            {{/each}}
          {{/let}}
        </t.Body>
      </Table>
    </DataTable>
  </template>
}
```

Its harness, `DataTableHarness`, is in `@ember-joinery/data-table/test-support`: it reads the
rows, the columns and their sort, the selection, the filter and the pages, and works them as a
user does.

Full documentation: the Data Table page of the guide at
**https://joegaudet.com/ember-joinery/guide/**. Design and examples ported from
[shadcn/ui](https://ui.shadcn.com/) (MIT), on [TanStack Table](https://tanstack.com/table)
(MIT).
