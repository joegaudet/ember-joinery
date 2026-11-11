import { SidebarProvider } from '@ember-joinery/ember'

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

<template>
  {{!
    Upstream's SidebarMenuButton and SidebarMenuSubButton asChild around an <a>: @as="a" for the
    button, and the sub button is an <a> already. Upstream marks "Data Fetching" isActive in its
    data and never passes it on, so no item shows active here either.
  }}
  <SidebarProvider as |sidebar|>
    <sidebar.Sidebar>
      <sidebar.Content>
        <sidebar.Group>
          <sidebar.GroupContent>
            <sidebar.Menu>
              {{#each items as |item|}}
                <sidebar.MenuItem>
                  <sidebar.MenuButton @as="a" href={{item.url}}>
                    <span>{{item.title}}</span>
                  </sidebar.MenuButton>
                  <sidebar.MenuSub>
                    {{#each item.items as |subItem|}}
                      <sidebar.MenuSubItem>
                        <sidebar.MenuSubButton href={{subItem.url}}>
                          <span>{{subItem.title}}</span>
                        </sidebar.MenuSubButton>
                      </sidebar.MenuSubItem>
                    {{/each}}
                  </sidebar.MenuSub>
                </sidebar.MenuItem>
              {{/each}}
            </sidebar.Menu>
          </sidebar.GroupContent>
        </sidebar.Group>
      </sidebar.Content>
    </sidebar.Sidebar>
  </SidebarProvider>
</template>
