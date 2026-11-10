import { ChevronDown } from 'lucide'
import { DropdownMenu, Icon, SidebarProvider } from '@ember-joinery/ember'

<template>
  {{! Upstream's DropdownMenuTrigger asChild makes the menu button the trigger, as m.trigger does. }}
  <SidebarProvider as |sidebar|>
    <sidebar.Sidebar>
      <sidebar.Header>
        <sidebar.Menu>
          <sidebar.MenuItem>
            <DropdownMenu as |m|>
              <sidebar.MenuButton
                class="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
                {{m.trigger}}
              >
                Select Workspace
                <Icon @icon={{ChevronDown}} class="ml-auto" />
              </sidebar.MenuButton>
              <m.Content class="w-(--radix-popper-anchor-width)">
                <m.Item>
                  <span>Acme Inc</span>
                </m.Item>
                <m.Item>
                  <span>Acme Corp.</span>
                </m.Item>
              </m.Content>
            </DropdownMenu>
          </sidebar.MenuItem>
        </sidebar.Menu>
      </sidebar.Header>
    </sidebar.Sidebar>
    <sidebar.Inset>
      <header class="flex h-12 items-center justify-between px-4">
        <sidebar.Trigger />
      </header>
    </sidebar.Inset>
  </SidebarProvider>
</template>
