import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { RovingFocusGroup } from '@ember-joinery/primitives/roving-focus'

type Mark = 'bold' | 'italic' | 'underline'
type Align = 'start' | 'center' | 'end'

const MARKS: { id: Mark; label: string }[] = [
  { id: 'bold', label: 'Bold' },
  { id: 'italic', label: 'Italic' },
  { id: 'underline', label: 'Underline' },
]

const ALIGNS: { id: Align; label: string }[] = [
  { id: 'start', label: 'Align start' },
  { id: 'center', label: 'Center' },
  { id: 'end', label: 'Align end' },
]

export default class RovingFocusToolbar extends Component {
  @tracked marks = new Set<Mark>(['bold'])
  @tracked align: Align = 'start'

  hasMark = (mark: Mark) => this.marks.has(mark)
  isAligned = (align: Align) => this.align === align

  toggle = (mark: Mark) => {
    const marks = new Set(this.marks)
    if (marks.has(mark)) marks.delete(mark)
    else marks.add(mark)
    this.marks = marks
  }

  setAlign = (align: Align) => (this.align = align)

  <template>
    <RovingFocusGroup
      @name="formatting"
      @orientation="horizontal"
      @loop={{true}}
      class="roving-toolbar"
      role="toolbar"
      aria-label="Formatting"
      as |group|
    >
      {{#each MARKS as |mark|}}
        <group.Item
          @as="button"
          @tabStopId={{mark.id}}
          type="button"
          aria-pressed={{if (this.hasMark mark.id) "true" "false"}}
          {{on "click" (fn this.toggle mark.id)}}
        >
          {{mark.label}}
        </group.Item>
      {{/each}}
      <span class="roving-toolbar-separator" role="separator" aria-orientation="vertical"></span>
      {{#each ALIGNS as |align|}}
        <group.Item
          @as="button"
          @tabStopId={{align.id}}
          type="button"
          aria-pressed={{if (this.isAligned align.id) "true" "false"}}
          {{on "click" (fn this.setAlign align.id)}}
        >
          {{align.label}}
        </group.Item>
      {{/each}}
    </RovingFocusGroup>
    <style>
      .roving-toolbar {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 0.25rem;
        padding: 0.25rem;
        border: 1px solid color-mix(in oklab, currentColor 20%, transparent);
        border-radius: 0.5rem;
      }
      .roving-toolbar button[aria-pressed="true"] {
        font-weight: 600;
        text-decoration: underline;
      }
      .roving-toolbar-separator {
        align-self: stretch;
        width: 1px;
        margin-inline: 0.25rem;
        background: color-mix(in oklab, currentColor 20%, transparent);
      }
    </style>
  </template>
}
