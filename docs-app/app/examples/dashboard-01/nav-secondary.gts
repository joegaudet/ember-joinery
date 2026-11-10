import type { TOC } from '@ember/component/template-only'
import { Icon, type IconNode, type SidebarBlockParams } from '@ember-joinery/ember'

export interface NavSecondaryItem {
  title: string
  url: string
  icon: IconNode
}

// Upstream spreads its other props on the SidebarGroup: here a caller's attributes.
const NavSecondary: TOC<{
  Args: { sidebar: SidebarBlockParams; items: NavSecondaryItem[] }
  Element: HTMLElement
}> = <template>
  <@sidebar.Group ...attributes>
    <@sidebar.GroupContent>
      <@sidebar.Menu>
        {{#each @items as |item|}}
          <@sidebar.MenuItem>
            <@sidebar.MenuButton @as="a" href={{item.url}}>
              <Icon @icon={{item.icon}} />
              <span>{{item.title}}</span>
            </@sidebar.MenuButton>
          </@sidebar.MenuItem>
        {{/each}}
      </@sidebar.Menu>
    </@sidebar.GroupContent>
  </@sidebar.Group>
</template>

export default NavSecondary
