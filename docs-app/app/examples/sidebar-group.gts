import { LifeBuoy, Send } from 'lucide'
import { Icon, SidebarProvider } from '@ember-joinery/ember'

<template>
  <SidebarProvider as |sidebar|>
    <sidebar.Sidebar>
      <sidebar.Content>
        <sidebar.Group>
          <sidebar.GroupLabel>Help</sidebar.GroupLabel>
          <sidebar.GroupContent>
            <sidebar.Menu>
              <sidebar.MenuItem>
                <sidebar.MenuButton>
                  <Icon @icon={{LifeBuoy}} />
                  Support
                </sidebar.MenuButton>
              </sidebar.MenuItem>
              <sidebar.MenuItem>
                <sidebar.MenuButton>
                  <Icon @icon={{Send}} />
                  Feedback
                </sidebar.MenuButton>
              </sidebar.MenuItem>
            </sidebar.Menu>
          </sidebar.GroupContent>
        </sidebar.Group>
      </sidebar.Content>
    </sidebar.Sidebar>
  </SidebarProvider>
</template>
