import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Button, DropdownMenu } from '@ember-joinery/ember'

export default class DropdownMenuCheckboxes extends Component {
  @tracked showStatusBar = true
  @tracked showActivityBar = false
  @tracked showPanel = false

  setShowStatusBar = (checked: boolean) => (this.showStatusBar = checked)
  setShowActivityBar = (checked: boolean) => (this.showActivityBar = checked)
  setShowPanel = (checked: boolean) => (this.showPanel = checked)

  <template>
    <DropdownMenu as |m|>
      <Button @variant="outline" {{m.trigger}}>Open</Button>
      <m.Content class="w-40">
        <m.Group>
          <m.Label>Appearance</m.Label>
          <m.CheckboxItem
            @checked={{this.showStatusBar}}
            @onCheckedChange={{this.setShowStatusBar}}
          >
            Status Bar
          </m.CheckboxItem>
          <m.CheckboxItem
            @checked={{this.showActivityBar}}
            @onCheckedChange={{this.setShowActivityBar}}
            @disabled={{true}}
          >
            Activity Bar
          </m.CheckboxItem>
          <m.CheckboxItem @checked={{this.showPanel}} @onCheckedChange={{this.setShowPanel}}>
            Panel
          </m.CheckboxItem>
        </m.Group>
      </m.Content>
    </DropdownMenu>
  </template>
}
