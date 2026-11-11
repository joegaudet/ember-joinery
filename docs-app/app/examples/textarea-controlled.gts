import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Button, Textarea } from '@ember-joinery/ember'

const LIMIT = 280

/**
 * Joinery's own example: upstream's Textarea is a plain <textarea>, so it has none for a
 * controlled value. The message is the parent's, so it can count the characters and clear it.
 */
export default class TextareaControlled extends Component {
  @tracked message = ''

  setMessage = (value: string) => (this.message = value)
  clear = () => (this.message = '')

  get left(): number {
    return LIMIT - this.message.length
  }

  <template>
    <div class="grid w-full max-w-xs gap-2">
      <Textarea
        @name="message"
        @value={{this.message}}
        @onValueChange={{this.setMessage}}
        maxlength={{LIMIT}}
        aria-label="Message"
        placeholder="Type your message here."
      />
      <div class="flex items-center justify-between">
        <p class="text-muted-foreground text-sm">
          <output data-test-left>{{this.left}}</output>
          characters left
        </p>
        <Button @variant="outline" @size="sm" @name="clear" {{on "click" this.clear}}>
          Clear
        </Button>
      </div>
    </div>
  </template>
}
