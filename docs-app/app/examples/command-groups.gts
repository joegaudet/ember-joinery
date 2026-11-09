import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { Calculator, Calendar, CreditCard, Settings, Smile, User } from 'lucide'
import { Button, Command, CommandDialog, Icon } from '@ember-joinery/ember'

export default class CommandWithGroups extends Component {
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
            <c.Group @heading="Suggestions">
              <c.Item>
                <Icon @icon={{Calendar}} />
                <span>Calendar</span>
              </c.Item>
              <c.Item>
                <Icon @icon={{Smile}} />
                <span>Search Emoji</span>
              </c.Item>
              <c.Item>
                <Icon @icon={{Calculator}} />
                <span>Calculator</span>
              </c.Item>
            </c.Group>
            <c.Separator />
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
