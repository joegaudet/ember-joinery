import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { scrollLock } from '@ember-joinery/primitives/scroll-lock'

const ITEMS = Array.from({ length: 30 }, (_, index) => `Item ${index + 1}`)

/**
 * A panel that locks the page's scroll while it is open. The wheel, or a finger, still scrolls
 * the panel itself, as far as its ends and no further.
 */
export default class ScrollLockPanel extends Component {
  @tracked open = false

  toggle = () => (this.open = !this.open)

  <template>
    <div class="grid justify-items-start gap-3" data-test-jn="scroll-lock-panel">
      <button
        type="button"
        class="rounded-md border px-3 py-1.5 text-sm"
        aria-expanded={{if this.open "true" "false"}}
        data-test-jn-part="toggle"
        {{on "click" this.toggle}}
      >{{if this.open "Unlock the page" "Lock the page"}}</button>
      {{#if this.open}}
        <ul
          class="h-40 w-56 overflow-y-auto rounded-md border p-2 text-sm"
          tabindex="0"
          aria-label="Items"
          data-test-jn-part="panel"
          {{scrollLock}}
        >
          {{#each ITEMS as |item|}}
            <li class="py-1">{{item}}</li>
          {{/each}}
        </ul>
      {{/if}}
    </div>
  </template>
}
