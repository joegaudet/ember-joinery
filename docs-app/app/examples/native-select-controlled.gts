import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Button, NativeSelect } from '@ember-joinery/ember'

/**
 * Joinery's own example: upstream has none for a controlled value. The status is the parent's:
 * the select shows it, @onValueChange hears each choice, and the button sets it too.
 */
export default class NativeSelectControlled extends Component {
  @tracked status = 'in-progress'

  setStatus = (value: string) => (this.status = value)
  markDone = () => (this.status = 'done')

  get isDone(): boolean {
    return this.status === 'done'
  }

  <template>
    <div class="flex items-center gap-2">
      <NativeSelect
        @name="status"
        @value={{this.status}}
        @onValueChange={{this.setStatus}}
        aria-label="Status"
        as |s|
      >
        <s.Option @value="todo">Todo</s.Option>
        <s.Option @value="in-progress">In Progress</s.Option>
        <s.Option @value="done">Done</s.Option>
        <s.Option @value="cancelled">Cancelled</s.Option>
      </NativeSelect>
      <Button
        @variant="outline"
        @name="mark-done"
        disabled={{this.isDone}}
        {{on "click" this.markDone}}
      >Mark as done</Button>
    </div>
  </template>
}
