import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { InHead } from '@ember-joinery/primitives/head'

/** A stylesheet only this part of the page needs, in <head> while it is wanted. */
export default class HeadStylesheet extends Component {
  @tracked highContrast = false

  toggle = () => (this.highContrast = !this.highContrast)

  <template>
    <div data-test-jn="contrast" class="contrast-demo">
      <button
        type="button"
        aria-pressed={{if this.highContrast "true" "false"}}
        data-test-jn-part="toggle"
        {{on "click" this.toggle}}
      >High contrast</button>
      <p data-test-jn-part="text">This text gets its colours from a stylesheet in the page's head.</p>
    </div>

    {{#if this.highContrast}}
      <InHead>
        <style data-test-head-stylesheet>
          .contrast-demo p {
            color: canvastext;
            background: canvas;
            outline: 2px solid;
          }
        </style>
      </InHead>
    {{/if}}
  </template>
}
