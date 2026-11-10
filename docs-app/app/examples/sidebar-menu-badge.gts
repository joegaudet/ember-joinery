import { Frame, LifeBuoy, Map, PieChart, Send } from 'lucide'
import { Icon, SidebarProvider } from '@ember-joinery/ember'

const projects = [
  {
    name: 'Design Engineering',
    url: '#',
    icon: Frame,
    badge: '24',
  },
  {
    name: 'Sales & Marketing',
    url: '#',
    icon: PieChart,
    badge: '12',
  },
  {
    name: 'Travel',
    url: '#',
    icon: Map,
    badge: '3',
  },
  {
    name: 'Support',
    url: '#',
    icon: LifeBuoy,
    badge: '21',
  },
  {
    name: 'Feedback',
    url: '#',
    icon: Send,
    badge: '8',
  },
]

<template>
  <SidebarProvider as |sidebar|>
    <sidebar.Sidebar>
      <sidebar.Content>
        <sidebar.Group>
          <sidebar.GroupLabel>Projects</sidebar.GroupLabel>
          <sidebar.GroupContent>
            <sidebar.Menu>
              {{#each projects as |project|}}
                <sidebar.MenuItem>
                  <sidebar.MenuButton
                    @as="a"
                    href={{project.url}}
                    class="group-has-[[data-state=open]]/menu-item:bg-sidebar-accent"
                  >
                    <Icon @icon={{project.icon}} />
                    <span>{{project.name}}</span>
                  </sidebar.MenuButton>
                  <sidebar.MenuBadge>{{project.badge}}</sidebar.MenuBadge>
                </sidebar.MenuItem>
              {{/each}}
            </sidebar.Menu>
          </sidebar.GroupContent>
        </sidebar.Group>
      </sidebar.Content>
    </sidebar.Sidebar>
  </SidebarProvider>
</template>
