import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { CreditCard, Settings, User } from 'lucide'
import { Button, Command, CommandDialog, Icon } from '@ember-joinery/ember'

export default class CommandWithShortcuts extends Component {
  @tracked open = false

  setOpen = (open: boolean) => (this.open = open)

  <template>
    <div class="flex flex-col gap-4">
      <Button @variant="outline" class="w-fit" {{on "click" (fn this.setOpen true)}}>
        Open Menu
      </Button>
      <CommandDialog @open={{this.open}} @onOpenChange={{this.setOpen}}>
        <Command as |c|>
          <c.Input placeholder="Type a command or search..." />
          <c.List>
            <c.Empty>No results found.</c.Empty>
            <c.Group @heading="Settings">
              <c.Item>
                <Icon @icon={{User}} />
                <span>Profile</span>
                <c.Shortcut>⌘P</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{CreditCard}} />
                <span>Billing</span>
                <c.Shortcut>⌘B</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{Settings}} />
                <span>Settings</span>
                <c.Shortcut>⌘S</c.Shortcut>
              </c.Item>
            </c.Group>
          </c.List>
        </Command>
      </CommandDialog>
    </div>
  </template>
}
