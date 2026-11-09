import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import {
  DirectionProvider,
  getDirection,
  type Direction,
} from '@ember-joinery/primitives/direction'

export default class DirectionProviderExample extends Component {
  @tracked dir: Direction = 'rtl'
  @tracked read: Direction | undefined

  get other(): Direction {
    return this.dir === 'rtl' ? 'ltr' : 'rtl'
  }

  flip = () => (this.dir = this.other)

  /** What a component inside would see when it needs the direction, as on a key press. */
  readDirection = (event: Event) => (this.read = getDirection(event.currentTarget as Element))

  <template>
    <button type="button" {{on "click" this.flip}}>Switch to {{this.other}}</button>
    <DirectionProvider @dir={{this.dir}} as |dir|>
      <div class="direction-card">
        <p>مرحبا بالعالم · Hello, world</p>
        <p>The provider says <code>{{dir}}</code>.</p>
        <button type="button" {{on "click" this.readDirection}}>Read it from here</button>
        {{#if this.read}}<output>getDirection() → {{this.read}}</output>{{/if}}
      </div>
    </DirectionProvider>
  </template>
}
