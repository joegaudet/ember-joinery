import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { Minus } from 'lucide'
import { Checkbox } from '@ember-joinery/ember'
import type { CheckedState } from '@ember-joinery/primitives/checkbox'

const ITEMS = [
  { id: 'hard-disks', label: 'Hard disks' },
  { id: 'external-disks', label: 'External disks' },
  { id: 'cds-dvds', label: 'CDs, DVDs, and iPods' },
  { id: 'connected-servers', label: 'Connected servers' },
]

/**
 * Joinery's own example: a "select all" checkbox that is indeterminate while only some of the
 * items are checked, and shows lucide's minus then. The items are upstream's checkbox-group's.
 */
export default class CheckboxIndeterminate extends Component {
  @tracked selected = new Set(['hard-disks', 'external-disks'])

  get all(): CheckedState {
    if (this.selected.size === 0) return false
    return this.selected.size === ITEMS.length ? true : 'indeterminate'
  }

  isSelected = (id: string): boolean => this.selected.has(id)

  selectAll = (checked: CheckedState): void => {
    this.selected = new Set(checked === true ? ITEMS.map(item => item.id) : [])
  }

  select = (id: string, checked: CheckedState): void => {
    const selected = new Set(this.selected)
    if (checked === true) selected.add(id)
    else selected.delete(id)
    this.selected = selected
  }

  <template>
    <div class="flex flex-col gap-3">
      <div class="flex items-center gap-3">
        <Checkbox
          id="show-all-checkbox"
          @name="all"
          @checked={{this.all}}
          @onCheckedChange={{this.selectAll}}
          @indeterminateIcon={{Minus}}
        />
        <label for="show-all-checkbox" class="text-sm leading-none font-medium select-none">
          Show these items on the desktop
        </label>
      </div>
      <div class="flex flex-col gap-3 ps-7">
        {{#each ITEMS as |item|}}
          <div class="flex items-center gap-3">
            <Checkbox
              id="{{item.id}}-checkbox"
              @name={{item.id}}
              @checked={{this.isSelected item.id}}
              @onCheckedChange={{fn this.select item.id}}
            />
            <label for="{{item.id}}-checkbox" class="text-sm leading-none select-none">
              {{item.label}}
            </label>
          </div>
        {{/each}}
      </div>
    </div>
  </template>
}
