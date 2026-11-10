import { Frame, LifeBuoy, Map, PieChart, Send } from 'lucide'
import { Icon, SidebarProvider } from '@ember-joinery/ember'

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

<template>
  {{! Upstream's SidebarMenuButton asChild around an <a> is @as="a". }}
  <SidebarProvider as |sidebar|>
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
  </SidebarProvider>
</template>
