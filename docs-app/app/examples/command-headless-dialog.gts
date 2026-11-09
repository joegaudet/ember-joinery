import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { Command, CommandDialog } from '@ember-joinery/primitives/command'

const COMMANDS = ['New File', 'New Folder', 'Find in Files', 'Open Settings', 'Toggle Theme']

/**
 * The primitive's CommandDialog, unstyled but for the classes here: ⌘K (Ctrl+K off a Mac) opens
 * it from anywhere on the page, and so does the button. Choosing a command closes it, as
 * ember-primitives' palette does with `@onSelect={{d.close}}`.
 */
export default class CommandHeadlessDialog extends Component {
  @tracked open = false
  @tracked ran = ''

  setOpen = (open: boolean) => (this.open = open)

  run = (command: string) => {
    this.ran = command
    this.open = false
  }

  <template>
    <div class="flex flex-col items-start gap-3 text-sm">
      <button
        type="button"
        class="rounded-md border px-3 py-1.5"
        {{on "click" (fn this.setOpen true)}}
      >Open the palette</button>
      <p>Or press ⌘K (Ctrl+K off a Mac).</p>
      {{#if this.ran}}
        <p>Ran: <strong data-test-ran>{{this.ran}}</strong></p>
      {{/if}}
    </div>
    <CommandDialog
      @open={{this.open}}
      @onOpenChange={{this.setOpen}}
      @hotkey="mod+k"
      @overlayClass="fixed inset-0 bg-black/40"
      class="fixed top-1/4 left-1/2 w-[min(90vw,28rem)] -translate-x-1/2 overflow-hidden rounded-xl bg-background shadow-lg"
    >
      <Command @onSelect={{this.run}} as |c|>
        <c.Input placeholder="Type a command…" class="w-full border-b px-4 py-3" />
        <c.List class="max-h-72 overflow-y-auto p-2">
          <c.Empty class="p-4 text-center">No commands match.</c.Empty>
          {{#each COMMANDS as |command|}}
            <c.Item class="cursor-default rounded-md px-3 py-2 data-[selected=true]:bg-muted">
              {{command}}
            </c.Item>
          {{/each}}
        </c.List>
      </Command>
    </CommandDialog>
  </template>
}
