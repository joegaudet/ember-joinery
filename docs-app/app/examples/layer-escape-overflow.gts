import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { array } from '@ember/helper'
import { on } from '@ember/modifier'
import { modifier } from 'ember-modifier'
import { anchorTo } from '@ember-joinery/primitives/anchor'
import { dismissable } from '@ember-joinery/primitives/dismiss'
import { topLayer } from '@ember-joinery/primitives/layer'

/** A card that clips what overflows it, and a popover from inside it that isn't clipped. */
export default class LayerEscapeOverflow extends Component {
  @tracked open = false

  /** Kept untracked: the popover renders after the button has. */
  button: HTMLElement | null = null

  keepButton = modifier((element: HTMLElement) => {
    this.button = element
  })

  toggle = () => (this.open = !this.open)
  close = () => (this.open = false)

  <template>
    <div class="layer-card" data-test-jn="clipping-card">
      <p>This card has <code>overflow: hidden</code>.</p>
      <button
        type="button"
        aria-expanded={{if this.open "true" "false"}}
        aria-controls="layer-escape-overflow-popover"
        data-test-jn-part="trigger"
        {{this.keepButton}}
        {{on "click" this.toggle}}
      >
        {{if this.open "Close" "Open"}}
        the popover
      </button>
      {{#if this.open}}
        <div
          id="layer-escape-overflow-popover"
          class="layer-popover"
          role="dialog"
          aria-label="Popover"
          data-test-jn-part="popover"
          {{topLayer}}
          {{dismissable onDismiss=this.close inside=(array this.button)}}
          {{anchorTo this.button side="bottom" sideOffset=8}}
        >
          In the top layer, so the card can't clip it.
        </div>
      {{/if}}
    </div>
    <style>
      .layer-card {
        overflow: hidden;
        width: 16rem;
        height: 7rem;
        padding: 1rem;
        border: 1px solid;
        border-radius: 0.5rem;
      }
      .layer-popover {
        width: 14rem;
        padding: 0.75rem;
        border: 1px solid;
        border-radius: 0.5rem;
      }
    </style>
  </template>
}
