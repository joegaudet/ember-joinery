import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { FloatingUI, type Align, type Side } from '@ember-joinery/primitives/anchor'
import { topLayer } from '@ember-joinery/primitives/layer'

const SIDES: Side[] = ['top', 'right', 'bottom', 'left']
const ALIGNS: Align[] = ['start', 'center', 'end']

function eq(a: unknown, b: unknown): boolean {
  return a === b
}

/** A label anchored to a button: pick its side and alignment, and it follows. */
export default class AnchorPlacement extends Component {
  @tracked side: Side = 'top'
  @tracked align: Align = 'center'

  setSide = (event: Event) => (this.side = (event.target as HTMLSelectElement).value as Side)
  setAlign = (event: Event) => (this.align = (event.target as HTMLSelectElement).value as Align)

  <template>
    <div class="anchor-demo" data-test-jn="anchor-demo">
      <label>
        Side
        <select data-test-jn-part="side" {{on "change" this.setSide}}>
          {{#each SIDES as |side|}}
            <option value={{side}} selected={{if (eq side this.side) true}}>{{side}}</option>
          {{/each}}
        </select>
      </label>
      <label>
        Align
        <select data-test-jn-part="align" {{on "change" this.setAlign}}>
          {{#each ALIGNS as |align|}}
            <option value={{align}} selected={{if (eq align this.align) true}}>{{align}}</option>
          {{/each}}
        </select>
      </label>
      <FloatingUI
        @side={{this.side}}
        @align={{this.align}}
        @sideOffset={{6}}
        as |reference floating|
      >
        <button type="button" class="anchor-demo-anchor" data-test-jn-part="anchor" {{reference}}>
          Anchor
        </button>
        {{#if floating}}
          <div class="anchor-demo-label" data-test-jn-part="label" {{topLayer}} {{floating}}>
            {{this.side}}
            {{this.align}}
          </div>
        {{/if}}
      </FloatingUI>
    </div>
    <style>
      .anchor-demo {
        display: grid;
        grid-template-columns: auto auto;
        justify-items: center;
        gap: 1rem 2rem;
        padding: 3rem 4rem;
      }
      .anchor-demo-anchor {
        grid-column: span 2;
        padding: 1rem 2rem;
      }
      .anchor-demo-label {
        padding: 0.25rem 0.5rem;
        border: 1px solid;
        border-radius: 0.25rem;
        font-size: 0.875rem;
      }
    </style>
  </template>
}
