import { on } from '@ember/modifier'
import { Frame, Map, PieChart, Plus } from 'lucide'
import { Icon, SidebarProvider, Toaster, toast } from '@ember-joinery/ember'

// The example's own Toaster, as upstream's, which the guide's (one per page) would show the
// toast again beside: so this one has an @id, and the toast names it.
const TOASTER = 'sidebar-group-action'
const toastOptions = { className: 'ml-[160px]' }
const showToast = () => toast('You clicked the group action!', { toasterId: TOASTER })

<template>
  <SidebarProvider as |sidebar|>
    <Toaster @id={{TOASTER}} @position="bottom-left" @toastOptions={{toastOptions}} />
    <sidebar.Sidebar>
      <sidebar.Content>
        <sidebar.Group>
          <sidebar.GroupLabel>Projects</sidebar.GroupLabel>
          <sidebar.GroupAction title="Add Project" {{on "click" showToast}}>
            <Icon @icon={{Plus}} />
            <span class="sr-only">Add Project</span>
          </sidebar.GroupAction>
          <sidebar.GroupContent>
            <sidebar.Menu>
              <sidebar.MenuItem>
                <sidebar.MenuButton @as="a" href="#">
                  <Icon @icon={{Frame}} />
                  <span>Design Engineering</span>
                </sidebar.MenuButton>
              </sidebar.MenuItem>
              <sidebar.MenuItem>
                <sidebar.MenuButton @as="a" href="#">
                  <Icon @icon={{PieChart}} />
                  <span>Sales & Marketing</span>
                </sidebar.MenuButton>
              </sidebar.MenuItem>
              <sidebar.MenuItem>
                <sidebar.MenuButton @as="a" href="#">
                  <Icon @icon={{Map}} />
                  <span>Travel</span>
                </sidebar.MenuButton>
              </sidebar.MenuItem>
            </sidebar.Menu>
          </sidebar.GroupContent>
        </sidebar.Group>
      </sidebar.Content>
    </sidebar.Sidebar>
  </SidebarProvider>
</template>
