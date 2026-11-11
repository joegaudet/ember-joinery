import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Button, DropdownMenu } from '@ember-joinery/ember'

export default class DropdownMenuRadioGroup extends Component {
  @tracked position = 'bottom'

  setPosition = (position: string) => (this.position = position)

  <template>
    <DropdownMenu as |m|>
      <Button @variant="outline" {{m.trigger}}>Open</Button>
      <m.Content class="w-32">
        <m.Group>
          <m.Label>Panel Position</m.Label>
          <m.RadioGroup @value={{this.position}} @onValueChange={{this.setPosition}} as |g|>
            <g.Item @value="top">Top</g.Item>
            <g.Item @value="bottom">Bottom</g.Item>
            <g.Item @value="right">Right</g.Item>
          </m.RadioGroup>
        </m.Group>
      </m.Content>
    </DropdownMenu>
  </template>
}
