import type { TOC } from '@ember/component/template-only'
import { Folder, MoreHorizontal, Share, Trash2 } from 'lucide'
import { DropdownMenu, Icon, type IconNode, type SidebarBlockParams } from '@ember-joinery/ember'

export interface NavDocumentsItem {
  name: string
  url: string
  icon: IconNode
}

// Upstream's useSidebar() gives isMobile; here the provider's state comes in @sidebar.
const NavDocuments: TOC<{ Args: { sidebar: SidebarBlockParams; items: NavDocumentsItem[] } }> =
  <template>
    <@sidebar.Group class="group-data-[collapsible=icon]:hidden">
      <@sidebar.GroupLabel>Documents</@sidebar.GroupLabel>
      <@sidebar.Menu>
        {{#each @items as |item|}}
          <@sidebar.MenuItem>
            <@sidebar.MenuButton @as="a" href={{item.url}}>
              <Icon @icon={{item.icon}} />
              <span>{{item.name}}</span>
            </@sidebar.MenuButton>
            <DropdownMenu as |m|>
              <@sidebar.MenuAction
                @showOnHover={{true}}
                class="rounded-sm data-[state=open]:bg-accent"
                {{m.trigger}}
              >
                <Icon @icon={{MoreHorizontal}} />
                <span class="sr-only">More</span>
              </@sidebar.MenuAction>
              <m.Content
                class="w-24 rounded-lg"
                @side={{if @sidebar.isMobile "bottom" "right"}}
                @align={{if @sidebar.isMobile "end" "start"}}
              >
                <m.Item>
                  <Icon @icon={{Folder}} />
                  <span>Open</span>
                </m.Item>
                <m.Item>
                  <Icon @icon={{Share}} />
                  <span>Share</span>
                </m.Item>
                <m.Separator />
                <m.Item @variant="destructive">
                  <Icon @icon={{Trash2}} />
                  <span>Delete</span>
                </m.Item>
              </m.Content>
            </DropdownMenu>
          </@sidebar.MenuItem>
        {{/each}}
        <@sidebar.MenuItem>
          <@sidebar.MenuButton class="text-sidebar-foreground/70">
            <Icon @icon={{MoreHorizontal}} class="text-sidebar-foreground/70" />
            <span>More</span>
          </@sidebar.MenuButton>
        </@sidebar.MenuItem>
      </@sidebar.Menu>
    </@sidebar.Group>
  </template>

export default NavDocuments
