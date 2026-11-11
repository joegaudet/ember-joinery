import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { bodyClass } from '@ember-joinery/primitives/body-class'

/** Locks the page's scrolling, as an open dialog might, with a class on <body>. */
export default class BodyClassLockScroll extends Component {
  @tracked locked = false

  toggle = () => (this.locked = !this.locked)

  <template>
    {{#if this.locked}}
      {{bodyClass "scroll-locked"}}
    {{/if}}
    <style>
      body.scroll-locked {
        overflow: hidden;
      }
    </style>

    <div data-test-jn="scroll-lock">
      <button
        type="button"
        aria-pressed={{if this.locked "true" "false"}}
        data-test-jn-part="toggle"
        {{on "click" this.toggle}}
      >Lock the page's scrolling</button>
      <p data-test-jn-part="status">
        The page
        {{if this.locked "can't scroll." "scrolls."}}
      </p>
    </div>
  </template>
}
