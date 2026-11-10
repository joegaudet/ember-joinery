import type { TOC } from '@ember/component/template-only'
import { LinkTo } from '@ember/routing'
import { Icon, type IconNode, type SidebarBlockParams } from '@ember-joinery/ember'

export interface NavSecondaryItem {
  title: string
  url: string
  icon: IconNode
  /** The demo's: the route the item links to, where the app has one. */
  route?: string
}

// The guide's dashboard-01 block (docs-app/app/examples/dashboard-01), as the demo copies it
// in: an item with a `route` links to it.
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
            {{#if item.route}}
              {{! The demo's: an item with a route is a link to it, the router's. }}
              <LinkTo @route={{item.route}} {{@sidebar.menuButton}}>
                <Icon @icon={{item.icon}} />
                <span>{{item.title}}</span>
              </LinkTo>
            {{else}}
              <@sidebar.MenuButton @as="a" href={{item.url}}>
                <Icon @icon={{item.icon}} />
                <span>{{item.title}}</span>
              </@sidebar.MenuButton>
            {{/if}}
          </@sidebar.MenuItem>
        {{/each}}
      </@sidebar.Menu>
    </@sidebar.GroupContent>
  </@sidebar.Group>
</template>

export default NavSecondary
