import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import {
  DirectionProvider,
  getDirection,
  type Direction,
} from '@ember-joinery/primitives/direction'

/** Content that reads the direction where it is, as a component does on a key press. */
class DirectionCard extends Component<{ Args: { dir: Direction } }> {
  @tracked read: Direction | undefined

  readDirection = (event: Event) => (this.read = getDirection(event.currentTarget as Element))

  <template>
    <div class="direction-card" data-test-jn="direction-card">
      <p>مرحبا بالعالم · Hello, world</p>
      <p>The provider says <code>{{@dir}}</code>.</p>
      <button type="button" data-test-jn-part="read" {{on "click" this.readDirection}}>
        Read it from here
      </button>
      {{#if this.read}}
        <output data-test-jn-part="result">getDirection() → {{this.read}}</output>
      {{/if}}
    </div>
  </template>
}

export default class DirectionProviderExample extends Component {
  @tracked dir: Direction = 'rtl'

  get other(): Direction {
    return this.dir === 'rtl' ? 'ltr' : 'rtl'
  }

  flip = () => (this.dir = this.other)

  <template>
    <div data-test-jn="direction-example">
      <button type="button" data-test-jn-part="switch" {{on "click" this.flip}}>
        Switch to
        {{this.other}}
      </button>
      <DirectionProvider @dir={{this.dir}} as |dir|>
        <DirectionCard @dir={{dir}} />
      </DirectionProvider>
    </div>
  </template>
}
