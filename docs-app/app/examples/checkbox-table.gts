import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { Checkbox, Table } from '@ember-joinery/ember'
import type { CheckedState } from '@ember-joinery/primitives/checkbox'

const tableData = [
  {
    id: '1',
    name: 'Sarah Chen',
    email: 'sarah.chen@example.com',
    role: 'Admin',
  },
  {
    id: '2',
    name: 'Marcus Rodriguez',
    email: 'marcus.rodriguez@example.com',
    role: 'User',
  },
  {
    id: '3',
    name: 'Priya Patel',
    email: 'priya.patel@example.com',
    role: 'User',
  },
  {
    id: '4',
    name: 'David Kim',
    email: 'david.kim@example.com',
    role: 'Editor',
  },
]

// Upstream leaves its checkboxes unnamed; an aria-label names each one, so the audit passes.
export default class CheckboxInTable extends Component {
  @tracked selectedRows = new Set(['1'])

  get selectAll(): boolean {
    return this.selectedRows.size === tableData.length
  }

  isSelected = (id: string): boolean => this.selectedRows.has(id)

  rowState = (id: string): string | undefined =>
    this.selectedRows.has(id) ? 'selected' : undefined

  handleSelectAll = (checked: CheckedState): void => {
    if (checked === true) {
      this.selectedRows = new Set(tableData.map(row => row.id))
    } else {
      this.selectedRows = new Set()
    }
  }

  handleSelectRow = (id: string, checked: CheckedState): void => {
    const newSelected = new Set(this.selectedRows)
    if (checked === true) {
      newSelected.add(id)
    } else {
      newSelected.delete(id)
    }
    this.selectedRows = newSelected
  }

  <template>
    <Table as |t|>
      <t.Header>
        <t.Row>
          <t.Head class="w-8">
            <Checkbox
              id="select-all-checkbox"
              name="select-all-checkbox"
              aria-label="Select all rows"
              @name="select-all"
              @checked={{this.selectAll}}
              @onCheckedChange={{this.handleSelectAll}}
            />
          </t.Head>
          <t.Head>Name</t.Head>
          <t.Head>Email</t.Head>
          <t.Head>Role</t.Head>
        </t.Row>
      </t.Header>
      <t.Body>
        {{#each tableData as |row|}}
          <t.Row data-state={{this.rowState row.id}}>
            <t.Cell>
              <Checkbox
                id="row-{{row.id}}-checkbox"
                name="row-{{row.id}}-checkbox"
                aria-label="Select {{row.name}}"
                @name="row-{{row.id}}"
                @checked={{this.isSelected row.id}}
                @onCheckedChange={{fn this.handleSelectRow row.id}}
              />
            </t.Cell>
            <t.Cell class="font-medium">{{row.name}}</t.Cell>
            <t.Cell>{{row.email}}</t.Cell>
            <t.Cell>{{row.role}}</t.Cell>
          </t.Row>
        {{/each}}
      </t.Body>
    </Table>
  </template>
}
