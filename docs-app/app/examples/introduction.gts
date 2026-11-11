import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'

/**
 * The shape of every example in this guide: a `.gts` component, shown live. Its state is in
 * ARIA (`aria-pressed`) and in a `data-state` attribute, and it carries the `data-test-jn`
 * attributes its harness finds it by, as Joinery's components do.
 */
export default class IntroductionExample extends Component {
  @tracked pressed = false

  toggle = () => (this.pressed = !this.pressed)

  <template>
    <button
      type="button"
      class="intro-toggle"
      aria-pressed={{if this.pressed "true" "false"}}
      data-state={{if this.pressed "on" "off"}}
      data-test-jn="toggle"
      data-test-jn-name="bold"
      {{on "click" this.toggle}}
    >
      Bold
    </button>
  </template>
}
