import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { array, fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { modifier } from 'ember-modifier'
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
import { RichTextEditor } from '@ember-joinery/tiptap'
import { DatePicker } from '@ember-joinery/power-calendar'
import { MaskedInput, PhoneInput, dateMask } from '@ember-joinery/maskito'
import { anchorTo } from '@ember-joinery/primitives/anchor'
import { dismissable } from '@ember-joinery/primitives/dismiss'
import { topLayer } from '@ember-joinery/primitives/layer'
import { As } from '@ember-joinery/primitives/as'
import { controllable } from '@ember-joinery/primitives/controllable-state'
import { idFor } from '@ember-joinery/primitives/id'
import { KeyCombo } from '@ember-joinery/primitives/keys'
import { part } from '@ember-joinery/primitives/part'
import { Presence } from '@ember-joinery/primitives/presence'

/**
 * A disclosure on the primitives, so this build covers what they depend on: `As` (an
 * @embroider/macros branch), `part` (ember-modifier) and `Presence` (@ember/test-waiters).
 */
class Disclosure extends Component {
  open = controllable(this, 'open', false)

  trigger = part(() => ({
    attributes: {
      'aria-expanded': String(this.open.value),
      'aria-controls': idFor(this, 'content'),
      'data-test-jn-part': 'trigger',
    },
    on: { click: () => this.open.set(open => !open) },
  }))

  <template>
    <div data-test-jn="disclosure">
      <As @tag="button" type="button" {{this.trigger}}>{{@label}}</As>
      <Presence @present={{this.open.value}} as |presence|>
        <div id={{idFor this "content"}} data-test-jn-part="content" {{presence.ref}}>
          {{yield}}
        </div>
      </Presence>
    </div>
  </template>
}

/**
 * A popover on the layering primitives, so this build also covers Floating UI (their one
 * runtime dependency outside Ember): the top layer, the anchor and the dismiss stack.
 */
class Tip extends Component {
  @tracked open = false
  button = null

  keepButton = modifier(element => {
    this.button = element
  })

  toggle = () => (this.open = !this.open)
  close = () => (this.open = false)

  <template>
    <div data-test-jn="tip">
      <button
        type="button"
        aria-expanded={{if this.open "true" "false"}}
        data-test-jn-part="trigger"
        {{this.keepButton}}
        {{on "click" this.toggle}}
      >{{@label}}</button>
      {{#if this.open}}
        <div
          role="dialog"
          aria-label={{@label}}
          data-test-jn-part="content"
          {{topLayer}}
          {{anchorTo this.button side="bottom" sideOffset=4}}
          {{dismissable onDismiss=this.close inside=(array this.button)}}
        >{{yield}}</div>
      {{/if}}
    </div>
  </template>
}

const install = 'pnpm add @ember-joinery/code-block'
const due = new Date(2026, 2, 4)
const date = dateMask()

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
    <h1>Joinery in a classic app</h1>
    <p>
      This app consumes Joinery's v2 addons through ember-auto-import, with no Vite. CI builds it
      and runs its smoke test.
    </p>
    <p>Search with <KeyCombo @name="search" @keys="Ctrl+K" />.</p>
    <Disclosure @label="Details">The primitives work here too.</Disclosure>
    <Tip @label="Help">Anchored in the top layer.</Tip>
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
    {{! The carousel add-on, so this build covers Embla, its one dependency outside Ember. }}
    <Carousel @name="slides" aria-label="Slides" style="width: 240px; margin: 0 48px" as |c|>
      <c.Content>
        <c.Item>One</c.Item>
        <c.Item>Two</c.Item>
        <c.Item>Three</c.Item>
      </c.Content>
      <c.Previous />
      <c.Next />
    </Carousel>
    {{! The file-upload add-on, so this build covers ember-file-upload, a v2 addon of its own. }}
    <FileUpload @name="attachments" @multiple={{true}} @label="Attachments" />
    {{! The data-table add-on, so this build covers TanStack Table's core. }}
    <Fruit />
    {{! The tiptap add-on, so this build covers Tiptap and ProseMirror, and its toolbar's menus. }}
    <RichTextEditor @name="notes" @label="Notes" @defaultValue="<p>Shipping today</p>" />
    {{! The power-calendar add-on, so this build covers ember-power-calendar, a v2 addon whose
        service its own app tree carries, and ember-concurrency. }}
    <DatePicker @name="due" @defaultValue={{due}} @locale="en-US" />
    {{! The maskito add-on, so this build covers Maskito and libphonenumber-js's metadata. }}
    <MaskedInput @name="date" @mask={{date}} aria-label="Date" placeholder="dd/mm/yyyy" />
    <PhoneInput @name="phone" @defaultCountry="GB" aria-label="Phone" />
  </main>
</template>
