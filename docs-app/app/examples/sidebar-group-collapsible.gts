import { ChevronDown, LifeBuoy, Send } from 'lucide'
import { Collapsible, Icon, SidebarProvider } from '@ember-joinery/ember'

<template>
  {{!
    Upstream's SidebarGroupLabel asChild around a CollapsibleTrigger: the label as a button
    (@as="button"), made the trigger by c.trigger.
  }}
  <SidebarProvider as |sidebar|>
    <sidebar.Sidebar>
      <sidebar.Content>
        <Collapsible @defaultOpen={{true}} class="group/collapsible" as |c|>
          <sidebar.Group>
            <sidebar.GroupLabel
              @as="button"
              class="text-sm hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
              {{c.trigger}}
            >
              Help
              <Icon
                @icon={{ChevronDown}}
                class="ml-auto transition-transform group-data-[state=open]/collapsible:rotate-180"
              />
            </sidebar.GroupLabel>
            <c.Content>
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
            </c.Content>
          </sidebar.Group>
        </Collapsible>
      </sidebar.Content>
    </sidebar.Sidebar>
  </SidebarProvider>
</template>
