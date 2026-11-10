import { Frame, LifeBuoy, Map, MoreHorizontal, PieChart, Send } from 'lucide'
import { DropdownMenu, Icon, SidebarProvider } from '@ember-joinery/ember'

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
  {{! Upstream's DropdownMenuTrigger asChild makes the action the trigger, as m.trigger does. }}
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
                  <DropdownMenu as |m|>
                    <sidebar.MenuAction {{m.trigger}}>
                      <Icon @icon={{MoreHorizontal}} />
                      <span class="sr-only">More</span>
                    </sidebar.MenuAction>
                    <m.Content @side="right" @align="start">
                      <m.Item>
                        <span>Edit Project</span>
                      </m.Item>
                      <m.Item>
                        <span>Delete Project</span>
                      </m.Item>
                    </m.Content>
                  </DropdownMenu>
                </sidebar.MenuItem>
              {{/each}}
            </sidebar.Menu>
          </sidebar.GroupContent>
        </sidebar.Group>
      </sidebar.Content>
    </sidebar.Sidebar>
  </SidebarProvider>
</template>
