import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Presence } from '@ember-joinery/primitives/presence'

export default class PresenceFade extends Component {
  @tracked open = true

  toggle = () => (this.open = !this.open)

  <template>
    <div data-test-jn="fading-panel">
      <button
        type="button"
        aria-expanded={{if this.open "true" "false"}}
        data-test-jn-part="toggle"
        {{on "click" this.toggle}}
      >
        {{if this.open "Hide" "Show"}}
      </button>
      <Presence @present={{this.open}} as |presence|>
        <div
          class="presence-panel"
          data-state={{if this.open "open" "closed"}}
          data-test-jn-part="panel"
          {{presence.ref}}
        >
          It fades out before it goes.
        </div>
      </Presence>
    </div>
    <style>
      @keyframes presence-in {
        from {
          opacity: 0;
          transform: scale(0.95);
        }
      }
      @keyframes presence-out {
        to {
          opacity: 0;
          transform: scale(0.95);
        }
      }
      .presence-panel {
        padding: 1rem;
        border: 1px solid;
        border-radius: 0.5rem;
      }
      .presence-panel[data-state="open"] {
        animation: presence-in 150ms ease-out;
      }
      .presence-panel[data-state="closed"] {
        animation: presence-out 150ms ease-in;
      }
    </style>
  </template>
}
