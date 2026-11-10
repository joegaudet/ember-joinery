import type { TOC } from '@ember/component/template-only'
import { Bell, CircleUserRound, CreditCard, EllipsisVertical, LogOut } from 'lucide'
import { Avatar, DropdownMenu, Icon, type SidebarBlockParams } from '@ember-joinery/ember'

export interface NavUserUser {
  name: string
  email: string
  avatar: string
}

// Upstream's useSidebar() gives isMobile; here the provider's state comes in @sidebar.
const NavUser: TOC<{ Args: { sidebar: SidebarBlockParams; user: NavUserUser } }> = <template>
  <@sidebar.Menu>
    <@sidebar.MenuItem>
      <DropdownMenu as |m|>
        <@sidebar.MenuButton
          @size="lg"
          class="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
          {{m.trigger}}
        >
          <Avatar class="h-8 w-8 rounded-lg grayscale" as |a|>
            <a.Image @src={{@user.avatar}} alt={{@user.name}} />
            <a.Fallback class="rounded-lg">CN</a.Fallback>
          </Avatar>
          <div class="grid flex-1 text-left text-sm leading-tight">
            <span class="truncate font-medium">{{@user.name}}</span>
            <span class="truncate text-xs text-muted-foreground">
              {{@user.email}}
            </span>
          </div>
          <Icon @icon={{EllipsisVertical}} class="ml-auto size-4" />
        </@sidebar.MenuButton>
        <m.Content
          class="w-(--radix-dropdown-menu-trigger-width) min-w-56 rounded-lg"
          @side={{if @sidebar.isMobile "bottom" "right"}}
          @align="end"
          @sideOffset={{4}}
        >
          <m.Label class="p-0 font-normal">
            <div class="flex items-center gap-2 px-1 py-1.5 text-left text-sm">
              <Avatar class="h-8 w-8 rounded-lg" as |a|>
                <a.Image @src={{@user.avatar}} alt={{@user.name}} />
                <a.Fallback class="rounded-lg">CN</a.Fallback>
              </Avatar>
              <div class="grid flex-1 text-left text-sm leading-tight">
                <span class="truncate font-medium">{{@user.name}}</span>
                <span class="truncate text-xs text-muted-foreground">
                  {{@user.email}}
                </span>
              </div>
            </div>
          </m.Label>
          <m.Separator />
          <m.Group>
            <m.Item>
              <Icon @icon={{CircleUserRound}} />
              Account
            </m.Item>
            <m.Item>
              <Icon @icon={{CreditCard}} />
              Billing
            </m.Item>
            <m.Item>
              <Icon @icon={{Bell}} />
              Notifications
            </m.Item>
          </m.Group>
          <m.Separator />
          <m.Item>
            <Icon @icon={{LogOut}} />
            Log out
          </m.Item>
        </m.Content>
      </DropdownMenu>
    </@sidebar.MenuItem>
  </@sidebar.Menu>
</template>

export default NavUser
