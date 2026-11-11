import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { Button, Drawer } from '@ember-joinery/ember'

export default class DrawerNonDismissible extends Component {
  @tracked open = false

  setOpen = (open: boolean): void => {
    this.open = open
  }

  <template>
    <Drawer @open={{this.open}} @onOpenChange={{this.setOpen}} @dismissible={{false}} as |d|>
      <Button @variant="outline" {{d.trigger}}>Open Drawer</Button>
      <d.Content>
        <div class="mx-auto w-full max-w-sm">
          <d.Header>
            <d.Title>A drawer that stays</d.Title>
            <d.Description>
              No drag, Escape or press outside closes it: only its button does.
            </d.Description>
          </d.Header>
          <d.Footer>
            <Button {{on "click" (fn this.setOpen false)}}>Got it</Button>
          </d.Footer>
        </div>
      </d.Content>
    </Drawer>
  </template>
}
