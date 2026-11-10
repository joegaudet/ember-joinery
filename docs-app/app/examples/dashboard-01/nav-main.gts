import type { TOC } from '@ember/component/template-only'
import { CirclePlus, Mail } from 'lucide'
import { Button, Icon, type IconNode, type SidebarBlockParams } from '@ember-joinery/ember'

export interface NavMainItem {
  title: string
  url: string
  icon?: IconNode
}

const NavMain: TOC<{ Args: { sidebar: SidebarBlockParams; items: NavMainItem[] } }> = <template>
  <@sidebar.Group>
    <@sidebar.GroupContent class="flex flex-col gap-2">
      <@sidebar.Menu>
        <@sidebar.MenuItem class="flex items-center gap-2">
          <@sidebar.MenuButton
            @tooltip="Quick Create"
            class="min-w-8 bg-primary text-primary-foreground duration-200 ease-linear hover:bg-primary/90 hover:text-primary-foreground active:bg-primary/90 active:text-primary-foreground"
          >
            <Icon @icon={{CirclePlus}} />
            <span>Quick Create</span>
          </@sidebar.MenuButton>
          <Button
            @size="icon"
            class="size-8 group-data-[collapsible=icon]:opacity-0"
            @variant="outline"
          >
            <Icon @icon={{Mail}} />
            <span class="sr-only">Inbox</span>
          </Button>
        </@sidebar.MenuItem>
      </@sidebar.Menu>
      <@sidebar.Menu>
        {{#each @items as |item|}}
          <@sidebar.MenuItem>
            <@sidebar.MenuButton @tooltip={{item.title}}>
              {{#if item.icon}}
                <Icon @icon={{item.icon}} />
              {{/if}}
              <span>{{item.title}}</span>
            </@sidebar.MenuButton>
          </@sidebar.MenuItem>
        {{/each}}
      </@sidebar.Menu>
    </@sidebar.GroupContent>
  </@sidebar.Group>
</template>

export default NavMain
