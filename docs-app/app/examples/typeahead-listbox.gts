import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn, uniqueId } from '@ember/helper'
import { on } from '@ember/modifier'
import { RovingFocusGroup } from '@ember-joinery/primitives/roving-focus'
import { typeahead } from '@ember-joinery/primitives/typeahead'

const FRUIT = ['Apple', 'Apricot', 'Banana', 'Blackberry', 'Blueberry', 'Cherry', 'Grape']

export default class TypeaheadListbox extends Component {
  @tracked selected = 'Banana'

  isSelected = (fruit: string) => this.selected === fruit
  select = (fruit: string) => (this.selected = fruit)

  /** Enter and Space choose the focused fruit; during a search, Space arrives prevented. */
  onKeyDown = (fruit: string, event: KeyboardEvent) => {
    if (event.defaultPrevented) return
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      this.select(fruit)
    }
  }

  <template>
    {{#let (uniqueId) as |labelId|}}
      <div class="typeahead-example">
        <span id={{labelId}}>Fruit</span>
        <RovingFocusGroup
          @name="fruit"
          @orientation="vertical"
          class="typeahead-listbox"
          role="listbox"
          aria-labelledby={{labelId}}
          {{typeahead}}
          as |group|
        >
          {{#each FRUIT as |fruit|}}
            <group.Item
              @tabStopId={{fruit}}
              @active={{this.isSelected fruit}}
              role="option"
              aria-selected={{if (this.isSelected fruit) "true" "false"}}
              {{on "click" (fn this.select fruit)}}
              {{on "keydown" (fn this.onKeyDown fruit)}}
            >
              {{fruit}}
            </group.Item>
          {{/each}}
        </RovingFocusGroup>
      </div>
    {{/let}}
    <style>
      .typeahead-example {
        display: grid;
        gap: 0.5rem;
        width: min(14rem, 100%);
      }
      .typeahead-listbox {
        display: grid;
        padding: 0.25rem;
        border: 1px solid color-mix(in oklab, currentColor 20%, transparent);
        border-radius: 0.5rem;
      }
      .typeahead-listbox [role="option"] {
        padding: 0.25rem 0.5rem;
        border-radius: 0.25rem;
        cursor: default;
      }
      .typeahead-listbox [role="option"]:focus-visible {
        outline: 2px solid;
        outline-offset: -2px;
      }
      .typeahead-listbox [aria-selected="true"] {
        font-weight: 600;
      }
    </style>
  </template>
}
