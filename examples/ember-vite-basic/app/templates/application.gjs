import Component from '@glimmer/component'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { ArrowUp } from 'lucide'
import { Button, Icon, Table } from '@ember-joinery/ember'
import { Carousel } from '@ember-joinery/carousel'
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'
import { FileUpload } from '@ember-joinery/file-upload'
import {
  DataTable,
  createSortedRowModel,
  createTable,
  flexComponent,
  rowSortingFeature,
  sortFn_alphanumeric,
  sortFn_text,
  tableFeatures,
} from '@ember-joinery/data-table'

const install = 'pnpm add @ember-joinery/code-block'
const slides = ['One', 'Two', 'Three']

const features = tableFeatures({
  rowSortingFeature,
  sortedRowModel: createSortedRowModel(),
  sortFns: { alphanumeric: sortFn_alphanumeric, text: sortFn_text },
})
const toggleSorting = column => column.toggleSorting(column.getIsSorted() === 'asc')
const NameHeader = <template>
  <Button @variant="ghost" {{on "click" (fn toggleSorting @column)}}>Name</Button>
</template>

/** A data table on TanStack Table's core, sorted by its header's button. */
class Fruit extends Component {
  table = createTable({
    features,
    data: [{ name: 'Cherry' }, { name: 'Apple' }, { name: 'Banana' }],
    columns: [{ accessorKey: 'name', header: flexComponent(NameHeader) }],
  })

  <template>
    <DataTable @table={{this.table}} @name="fruit" style="width: 240px" as |dt|>
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

<template>
  <main>
    <h1>Joinery in a Vite app</h1>
    <p>
      This app imports Joinery's packages and CSS the way a Vite (Embroider) app does. CI builds it
      and runs its smoke test.
    </p>
    <p>
      <Button @name="save" @variant="outline">Save</Button>
      <Button @name="up" @size="icon" aria-label="Back to top"><Icon @icon={{ArrowUp}} /></Button>
    </p>
    <CodeBlock @name="install" as |b|>
      <b.Header>
        <b.Title>Terminal</b.Title>
        <b.Actions><b.CopyButton @value={{install}} /></b.Actions>
      </b.Header>
      <b.Content>
        {{#each (highlightedCode install "bash") as |line|}}<b.Line @code={{line}} />{{/each}}
      </b.Content>
    </CodeBlock>
    <Carousel @name="slides" aria-label="Slides" style="width: 240px; margin: 0 48px" as |c|>
      <c.Content>
        {{#each slides as |slide|}}
          <c.Item>{{slide}}</c.Item>
        {{/each}}
      </c.Content>
      <c.Previous />
      <c.Next />
    </Carousel>
    <FileUpload @name="attachments" @multiple={{true}} @label="Attachments" />
    <Fruit />
  </main>
</template>
