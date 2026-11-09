import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { array } from '@ember/helper'
import { on } from '@ember/modifier'
import { modifier } from 'ember-modifier'
import { anchorTo } from '@ember-joinery/primitives/anchor'
import { dismissable } from '@ember-joinery/primitives/dismiss'
import { topLayer } from '@ember-joinery/primitives/layer'

/**
 * A panel with a nested panel inside it. Escape closes the top one only; a press outside
 * closes each panel it lands outside of, and a press in the nested one is inside both.
 */
export default class DismissNested extends Component {
  @tracked open = false
  @tracked moreOpen = false

  // Kept untracked: each panel renders after its button has.
  button: HTMLElement | null = null
  moreButton: HTMLElement | null = null

  keepButton = modifier((element: HTMLElement) => {
    this.button = element
  })

  keepMoreButton = modifier((element: HTMLElement) => {
    this.moreButton = element
  })

  toggle = () => {
    this.open = !this.open
    if (!this.open) this.moreOpen = false
  }

  toggleMore = () => (this.moreOpen = !this.moreOpen)
  close = () => (this.open = this.moreOpen = false)
  closeMore = () => (this.moreOpen = false)

  <template>
    <div data-test-jn="nested-panels">
      <button
        type="button"
        aria-expanded={{if this.open "true" "false"}}
        data-test-jn-part="trigger"
        {{this.keepButton}}
        {{on "click" this.toggle}}
      >Settings</button>
      {{#if this.open}}
        <div
          class="dismiss-panel"
          role="dialog"
          aria-label="Settings"
          data-test-jn-part="panel"
          {{topLayer}}
          {{dismissable onDismiss=this.close inside=(array this.button)}}
          {{anchorTo this.button side="bottom" align="start" sideOffset=6}}
        >
          <p>Press Escape: only the top panel closes.</p>
          <button
            type="button"
            aria-expanded={{if this.moreOpen "true" "false"}}
            data-test-jn-part="more-trigger"
            {{this.keepMoreButton}}
            {{on "click" this.toggleMore}}
          >More</button>
          {{#if this.moreOpen}}
            <div
              class="dismiss-panel"
              role="dialog"
              aria-label="More settings"
              data-test-jn-part="more-panel"
              {{topLayer}}
              {{dismissable onDismiss=this.closeMore inside=(array this.moreButton)}}
              {{anchorTo this.moreButton side="right" align="start" sideOffset=6}}
            >
              <p>A press here is inside both panels.</p>
            </div>
          {{/if}}
        </div>
      {{/if}}
    </div>
    <style>
      .dismiss-panel {
        width: 14rem;
        padding: 0.75rem;
        border: 1px solid;
        border-radius: 0.5rem;
      }
      .dismiss-panel p {
        margin: 0 0 0.5rem;
      }
    </style>
  </template>
}
