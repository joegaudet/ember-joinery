import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Frame, LifeBuoy, Map, PanelLeftClose, PanelLeftOpen, PieChart, Send } from 'lucide'
import { Button, Icon, SidebarProvider } from '@ember-joinery/ember'

const projects = [
  {
    name: 'Design Engineering',
    url: '#',
    icon: Frame,
  },
  {
    name: 'Sales & Marketing',
    url: '#',
    icon: PieChart,
  },
  {
    name: 'Travel',
    url: '#',
    icon: Map,
  },
  {
    name: 'Support',
    url: '#',
    icon: LifeBuoy,
  },
  {
    name: 'Feedback',
    url: '#',
    icon: Send,
  },
]

export default class AppSidebar extends Component {
  @tracked open = true

  setOpen = (open: boolean) => (this.open = open)
  toggle = () => (this.open = !this.open)

  <template>
    <SidebarProvider @open={{this.open}} @onOpenChange={{this.setOpen}} as |sidebar|>
      <sidebar.Sidebar>
        <sidebar.Content>
          <sidebar.Group>
            <sidebar.GroupLabel>Projects</sidebar.GroupLabel>
            <sidebar.GroupContent>
              <sidebar.Menu>
                {{#each projects as |project|}}
                  <sidebar.MenuItem>
                    <sidebar.MenuButton @as="a" href={{project.url}}>
                      <Icon @icon={{project.icon}} />
                      <span>{{project.name}}</span>
                    </sidebar.MenuButton>
                  </sidebar.MenuItem>
                {{/each}}
              </sidebar.Menu>
            </sidebar.GroupContent>
          </sidebar.Group>
        </sidebar.Content>
      </sidebar.Sidebar>
      <sidebar.Inset>
        <header class="flex h-12 items-center justify-between px-4">
          <Button @size="sm" @variant="ghost" {{on "click" this.toggle}}>
            {{#if this.open}}
              <Icon @icon={{PanelLeftClose}} />
            {{else}}
              <Icon @icon={{PanelLeftOpen}} />
            {{/if}}
            <span>{{if this.open "Close" "Open"}} Sidebar</span>
          </Button>
        </header>
      </sidebar.Inset>
    </SidebarProvider>
  </template>
}
