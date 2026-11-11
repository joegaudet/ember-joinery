import { ChevronRight } from 'lucide'
import { Collapsible, Icon, SidebarProvider } from '@ember-joinery/ember'

const items = [
  {
    title: 'Getting Started',
    url: '#',
    items: [
      {
        title: 'Installation',
        url: '#',
      },
      {
        title: 'Project Structure',
        url: '#',
      },
    ],
  },
  {
    title: 'Build Your Application',
    url: '#',
    items: [
      {
        title: 'Routing',
        url: '#',
      },
      {
        title: 'Data Fetching',
        url: '#',
        isActive: true,
      },
      {
        title: 'Rendering',
        url: '#',
      },
      {
        title: 'Caching',
        url: '#',
      },
      {
        title: 'Styling',
        url: '#',
      },
      {
        title: 'Optimizing',
        url: '#',
      },
      {
        title: 'Configuring',
        url: '#',
      },
      {
        title: 'Testing',
        url: '#',
      },
      {
        title: 'Authentication',
        url: '#',
      },
      {
        title: 'Deploying',
        url: '#',
      },
      {
        title: 'Upgrading',
        url: '#',
      },
      {
        title: 'Examples',
        url: '#',
      },
    ],
  },
  {
    title: 'API Reference',
    url: '#',
    items: [
      {
        title: 'Components',
        url: '#',
      },
      {
        title: 'File Conventions',
        url: '#',
      },
      {
        title: 'Functions',
        url: '#',
      },
      {
        title: 'next.config.js Options',
        url: '#',
      },
      {
        title: 'CLI',
        url: '#',
      },
      {
        title: 'Edge Runtime',
        url: '#',
      },
    ],
  },
  {
    title: 'Architecture',
    url: '#',
    items: [
      {
        title: 'Accessibility',
        url: '#',
      },
      {
        title: 'Fast Refresh',
        url: '#',
      },
      {
        title: 'Next.js Compiler',
        url: '#',
      },
      {
        title: 'Supported Browsers',
        url: '#',
      },
      {
        title: 'Turbopack',
        url: '#',
      },
    ],
  },
]

const isFirst = (index: number) => index === 0

<template>
  {{!
    Upstream wraps each SidebarMenuItem in a Collapsible's <div>, which puts a <div> straight
    inside the menu's <ul>: a list holds only <li>s, which the accessibility audit checks. So the
    Collapsible is the menu item, as sidebar-demo's is (its asChild): an <li> (@as="li") made the
    item by sidebar.menuItem, the same element as upstream's but for the <div> around it. Its
    CollapsibleTrigger asChild is the menu button, made the trigger by c.trigger. Upstream marks
    "Data Fetching" isActive in its data and never passes it on, so no item shows active here
    either.
  }}
  <SidebarProvider as |sidebar|>
    <sidebar.Sidebar>
      <sidebar.Content>
        <sidebar.Group>
          <sidebar.GroupContent>
            <sidebar.Menu>
              {{#each items as |item index|}}
                <Collapsible
                  @as="li"
                  class="group/collapsible"
                  @defaultOpen={{isFirst index}}
                  {{sidebar.menuItem}}
                  as |c|
                >
                  <sidebar.MenuButton {{c.trigger}}>
                    <span>{{item.title}}</span>
                    <Icon
                      @icon={{ChevronRight}}
                      class="ml-auto transition-transform group-data-[state=open]/collapsible:rotate-90"
                    />
                  </sidebar.MenuButton>
                  <c.Content>
                    <sidebar.MenuSub>
                      {{#each item.items as |subItem|}}
                        <sidebar.MenuSubItem>
                          <sidebar.MenuSubButton href={{subItem.url}}>
                            <span>{{subItem.title}}</span>
                          </sidebar.MenuSubButton>
                        </sidebar.MenuSubItem>
                      {{/each}}
                    </sidebar.MenuSub>
                  </c.Content>
                </Collapsible>
              {{/each}}
            </sidebar.Menu>
          </sidebar.GroupContent>
        </sidebar.Group>
      </sidebar.Content>
    </sidebar.Sidebar>
  </SidebarProvider>
</template>
