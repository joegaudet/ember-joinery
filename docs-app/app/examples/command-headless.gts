import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { array } from '@ember/helper'
import { Command } from '@ember-joinery/primitives/command'

const PAGES = [
  { label: 'Installation', about: 'Adding Joinery to an app' },
  { label: 'Accordion', about: 'A vertically stacked set of headings' },
  { label: 'Dialog', about: 'A window over the page' },
  { label: 'Theming', about: 'Colours, radius and dark mode' },
]

/**
 * The primitive, unstyled but for the classes here: a search box over the docs' pages, with no
 * dialog around it. It filters as you type (an item's keywords count, so "window" finds
 * Dialog), says how many results there are, and Enter or a click opens one.
 */
export default class CommandHeadless extends Component {
  @tracked opened = ''

  open = (page: string) => (this.opened = page)

  <template>
    <div class="flex w-full max-w-sm flex-col gap-3">
      <Command
        @label="Search the docs"
        @onSelect={{this.open}}
        class="overflow-hidden rounded-lg border"
        as |c|
      >
        <c.Input placeholder="Search the docs…" class="w-full border-b px-3 py-2 text-sm" />
        <c.List class="max-h-60 overflow-y-auto p-1">
          <c.Empty class="p-4 text-center text-sm">Nothing matches.</c.Empty>
          {{#each PAGES as |page|}}
            <c.Item
              @value={{page.label}}
              @keywords={{array page.about}}
              class="grid cursor-default rounded-md px-3 py-2 data-[selected=true]:bg-muted"
            >
              <span class="text-sm font-medium">{{page.label}}</span>
              <span class="text-xs">{{page.about}}</span>
            </c.Item>
          {{/each}}
        </c.List>
      </Command>
      {{#if this.opened}}
        <p class="text-sm">Opened: <strong data-test-opened>{{this.opened}}</strong></p>
      {{/if}}
    </div>
  </template>
}
