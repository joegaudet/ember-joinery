import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { nativeValue } from '@ember-joinery/primitives/native-value'
import { Button, asInput } from '@ember-joinery/ember'

/**
 * An input of your own, with Joinery's look (asInput) and Radix's value pattern (nativeValue):
 * it keeps its own value from defaultValue, tells the parent each change, and goes back to
 * "Ada" when the form resets.
 */
export default class NativeValueForm extends Component {
  @tracked heard = 'Ada'

  hear = (value: string) => (this.heard = value)

  <template>
    <form class="flex w-full max-w-xs flex-col gap-2" aria-label="Profile">
      <input
        aria-label="Name"
        {{asInput name="name"}}
        {{nativeValue defaultValue="Ada" onValueChange=this.hear}}
      />
      <p class="text-muted-foreground text-sm">
        The parent heard:
        <output data-test-heard>{{this.heard}}</output>
      </p>
      <Button @variant="outline" @name="reset" type="reset" class="self-start">Reset</Button>
    </form>
  </template>
}
