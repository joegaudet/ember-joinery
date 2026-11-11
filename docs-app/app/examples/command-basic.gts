import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { Button, Command, CommandDialog } from '@ember-joinery/ember'

export default class CommandBasic extends Component {
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
              <c.Item>Calendar</c.Item>
              <c.Item>Search Emoji</c.Item>
              <c.Item>Calculator</c.Item>
            </c.Group>
          </c.List>
        </Command>
      </CommandDialog>
    </div>
  </template>
}
