import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { modifier } from 'ember-modifier'
import { inertOthers } from '@ember-joinery/primitives/hide-others'

const CARDS = ['Profile', 'Billing', 'Security']

/** While its element is rendered, everything else on the page is inert. */
const spotlight = modifier((element: Element) => inertOthers(element))

/**
 * Puts one card in the spotlight: everything else on the page goes inert (no focus, no clicks,
 * nothing read aloud), as behind a modal dialog, until you're done.
 */
export default class HideOthersSpotlight extends Component {
  @tracked focused: string | undefined

  show = (card: string | undefined) => (this.focused = card)

  isFocused = (card: string) => this.focused === card

  <template>
    <div class="flex flex-wrap gap-3" data-test-jn="spotlight">
      {{#each CARDS as |card|}}
        {{#if (this.isFocused card)}}
          <section
            class="grid w-40 gap-2 rounded-md border-2 border-primary p-3 text-sm"
            aria-label={{card}}
            data-test-jn-part="card"
            data-test-jn-value={{card}}
            {{spotlight}}
          >
            <p class="font-medium">{{card}}</p>
            <button
              type="button"
              class="rounded-md border px-2 py-1"
              {{on "click" (fn this.show undefined)}}
            >Done</button>
          </section>
        {{else}}
          <section
            class="grid w-40 gap-2 rounded-md border p-3 text-sm"
            aria-label={{card}}
            data-test-jn-part="card"
            data-test-jn-value={{card}}
          >
            <p class="font-medium">{{card}}</p>
            <button
              type="button"
              class="rounded-md border px-2 py-1"
              {{on "click" (fn this.show card)}}
            >Spotlight</button>
          </section>
        {{/if}}
      {{/each}}
    </div>
  </template>
}
