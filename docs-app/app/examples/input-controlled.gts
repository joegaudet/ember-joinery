import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Input } from '@ember-joinery/ember'

/**
 * Joinery's own example: upstream's Input is a plain <input>, so it has none for a controlled
 * value. The username is the parent's: @onValueChange hears each change, and the parent keeps
 * it in lower case without spaces, which is what the input then shows.
 */
export default class InputControlled extends Component {
  @tracked username = 'ada'

  setUsername = (value: string) => (this.username = value.toLowerCase().replace(/\s+/g, ''))

  <template>
    <div class="flex w-full max-w-xs flex-col gap-2">
      <Input
        @name="username"
        @value={{this.username}}
        @onValueChange={{this.setUsername}}
        aria-label="Username"
        placeholder="username"
      />
      <p class="text-muted-foreground text-sm">
        Your profile:
        <output data-test-username>example.com/@{{this.username}}</output>
      </p>
    </div>
  </template>
}
