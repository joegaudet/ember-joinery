import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import type { TOC } from '@ember/component/template-only'
import {
  AudioWaveform,
  BadgeCheck,
  Bell,
  BookOpen,
  Bot,
  ChevronRight,
  ChevronsUpDown,
  Command,
  CreditCard,
  Folder,
  Forward,
  Frame,
  GalleryVerticalEnd,
  LogOut,
  Map,
  MoreHorizontal,
  PieChart,
  Plus,
  Settings2,
  Sparkles,
  SquareTerminal,
  Trash2,
} from 'lucide'
import {
  Avatar,
  Collapsible,
  DropdownMenu,
  Icon,
  SidebarProvider,
  type IconNode,
  type SidebarBlockParams,
} from '@ember-joinery/ember'

// This is sample data.
const data = {
  user: {
    name: 'shadcn',
    email: 'm@example.com',
    avatar: '/avatars/shadcn.jpg',
  },
  teams: [
    {
      name: 'Acme Inc',
      logo: GalleryVerticalEnd,
      plan: 'Enterprise',
    },
    {
      name: 'Acme Corp.',
      logo: AudioWaveform,
      plan: 'Startup',
    },
    {
      name: 'Evil Corp.',
      logo: Command,
      plan: 'Free',
    },
  ],
  navMain: [
    {
      title: 'Playground',
      url: '#',
      icon: SquareTerminal,
      isActive: true,
      items: [
        {
          title: 'History',
          url: '#',
        },
        {
          title: 'Starred',
          url: '#',
        },
        {
          title: 'Settings',
          url: '#',
        },
      ],
    },
    {
      title: 'Models',
      url: '#',
      icon: Bot,
      items: [
        {
          title: 'Genesis',
          url: '#',
        },
        {
          title: 'Explorer',
          url: '#',
        },
        {
          title: 'Quantum',
          url: '#',
        },
      ],
    },
    {
      title: 'Documentation',
      url: '#',
      icon: BookOpen,
      items: [
        {
          title: 'Introduction',
          url: '#',
        },
        {
          title: 'Get Started',
          url: '#',
        },
        {
          title: 'Tutorials',
          url: '#',
        },
        {
          title: 'Changelog',
          url: '#',
        },
      ],
    },
    {
      title: 'Settings',
      url: '#',
      icon: Settings2,
      items: [
        {
          title: 'General',
          url: '#',
        },
        {
          title: 'Team',
          url: '#',
        },
        {
          title: 'Billing',
          url: '#',
        },
        {
          title: 'Limits',
          url: '#',
        },
      ],
    },
  ],
  projects: [
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
  ],
}

interface Team {
  name: string
  logo: IconNode
  plan: string
}

const shortcut = (index: number) => `⌘${index + 1}`

// Upstream's components call useSidebar(); here they take what the SidebarProvider yields.
class TeamSwitcher extends Component<{ Args: { sidebar: SidebarBlockParams; teams: Team[] } }> {
  // Upstream's useState(teams[0]): the first team until another is chosen.
  @tracked chosenTeam: Team | undefined

  get activeTeam(): Team | undefined {
    return this.chosenTeam ?? this.args.teams[0]
  }

  setActiveTeam = (team: Team) => (this.chosenTeam = team)

  <template>
    {{#if this.activeTeam}}
      <@sidebar.Menu>
        <@sidebar.MenuItem>
          <DropdownMenu as |m|>
            <@sidebar.MenuButton
              @size="lg"
              class="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
              {{m.trigger}}
            >
              <div
                class="flex aspect-square size-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground"
              >
                <Icon @icon={{this.activeTeam.logo}} class="size-4" />
              </div>
              <div class="grid flex-1 text-left text-sm leading-tight">
                <span class="truncate font-medium">{{this.activeTeam.name}}</span>
                <span class="truncate text-xs">{{this.activeTeam.plan}}</span>
              </div>
              <Icon @icon={{ChevronsUpDown}} class="ml-auto" />
            </@sidebar.MenuButton>
            <m.Content
              class="w-(--radix-dropdown-menu-trigger-width) min-w-56 rounded-lg"
              @align="start"
              @side={{if @sidebar.isMobile "bottom" "right"}}
              @sideOffset={{4}}
            >
              <m.Group>
                <m.Label class="text-xs text-muted-foreground">
                  Teams
                </m.Label>
                {{#each @teams as |team index|}}
                  <m.Item @onSelect={{fn this.setActiveTeam team}} class="gap-2 p-2">
                    <div class="flex size-6 items-center justify-center rounded-md border">
                      <Icon @icon={{team.logo}} class="size-3.5 shrink-0" />
                    </div>
                    {{team.name}}
                    <m.Shortcut>{{shortcut index}}</m.Shortcut>
                  </m.Item>
                {{/each}}
              </m.Group>
              <m.Separator />
              <m.Group>
                <m.Item class="gap-2 p-2">
                  <div
                    class="flex size-6 items-center justify-center rounded-md border bg-transparent"
                  >
                    <Icon @icon={{Plus}} class="size-4" />
                  </div>
                  <div class="font-medium text-muted-foreground">
                    Add team
                  </div>
                </m.Item>
              </m.Group>
            </m.Content>
          </DropdownMenu>
        </@sidebar.MenuItem>
      </@sidebar.Menu>
    {{/if}}
  </template>
}

interface NavItem {
  title: string
  url: string
  icon?: IconNode
  isActive?: boolean
  items?: { title: string; url: string }[]
}

// Upstream's Collapsible asChild makes the SidebarMenuItem the collapsible: an <li> (@as) made
// the item by sidebar.menuItem. Its CollapsibleTrigger asChild is the menu button (c.trigger).
const NavMain: TOC<{ Args: { sidebar: SidebarBlockParams; items: NavItem[] } }> = <template>
  <@sidebar.Group>
    <@sidebar.GroupLabel>Platform</@sidebar.GroupLabel>
    <@sidebar.Menu>
      {{#each @items as |item|}}
        <Collapsible
          @as="li"
          @defaultOpen={{item.isActive}}
          class="group/collapsible"
          {{@sidebar.menuItem}}
          as |c|
        >
          <@sidebar.MenuButton @tooltip={{item.title}} {{c.trigger}}>
            {{#if item.icon}}
              <Icon @icon={{item.icon}} />
            {{/if}}
            <span>{{item.title}}</span>
            <Icon
              @icon={{ChevronRight}}
              class="ml-auto transition-transform duration-200 group-data-[state=open]/collapsible:rotate-90"
            />
          </@sidebar.MenuButton>
          <c.Content>
            <@sidebar.MenuSub>
              {{#each item.items as |subItem|}}
                <@sidebar.MenuSubItem>
                  <@sidebar.MenuSubButton href={{subItem.url}}>
                    <span>{{subItem.title}}</span>
                  </@sidebar.MenuSubButton>
                </@sidebar.MenuSubItem>
              {{/each}}
            </@sidebar.MenuSub>
          </c.Content>
        </Collapsible>
      {{/each}}
    </@sidebar.Menu>
  </@sidebar.Group>
</template>

interface Project {
  name: string
  url: string
  icon: IconNode
}

const NavProjects: TOC<{ Args: { sidebar: SidebarBlockParams; projects: Project[] } }> = <template>
  <@sidebar.Group class="group-data-[collapsible=icon]:hidden">
    <@sidebar.GroupLabel>Projects</@sidebar.GroupLabel>
    <@sidebar.Menu>
      {{#each @projects as |item|}}
        <@sidebar.MenuItem>
          <@sidebar.MenuButton @as="a" href={{item.url}}>
            <Icon @icon={{item.icon}} />
            <span>{{item.name}}</span>
          </@sidebar.MenuButton>
          <DropdownMenu as |m|>
            <@sidebar.MenuAction @showOnHover={{true}} {{m.trigger}}>
              <Icon @icon={{MoreHorizontal}} />
              <span class="sr-only">More</span>
            </@sidebar.MenuAction>
            <m.Content
              class="w-48 rounded-lg"
              @side={{if @sidebar.isMobile "bottom" "right"}}
              @align={{if @sidebar.isMobile "end" "start"}}
            >
              <m.Group>
                <m.Item>
                  <Icon @icon={{Folder}} class="text-muted-foreground" />
                  <span>View Project</span>
                </m.Item>
                <m.Item>
                  <Icon @icon={{Forward}} class="text-muted-foreground" />
                  <span>Share Project</span>
                </m.Item>
              </m.Group>
              <m.Separator />
              <m.Group>
                <m.Item>
                  <Icon @icon={{Trash2}} class="text-muted-foreground" />
                  <span>Delete Project</span>
                </m.Item>
              </m.Group>
            </m.Content>
          </DropdownMenu>
        </@sidebar.MenuItem>
      {{/each}}
      <@sidebar.MenuItem>
        <@sidebar.MenuButton class="text-sidebar-foreground/70">
          <Icon @icon={{MoreHorizontal}} class="text-sidebar-foreground/70" />
          <span>More</span>
        </@sidebar.MenuButton>
      </@sidebar.MenuItem>
    </@sidebar.Menu>
  </@sidebar.Group>
</template>

interface User {
  name: string
  email: string
  avatar: string
}

const NavUser: TOC<{ Args: { sidebar: SidebarBlockParams; user: User } }> = <template>
  <@sidebar.Menu>
    <@sidebar.MenuItem>
      <DropdownMenu as |m|>
        <@sidebar.MenuButton
          @size="lg"
          class="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
          {{m.trigger}}
        >
          <Avatar class="h-8 w-8 rounded-lg" as |a|>
            <a.Image @src={{@user.avatar}} alt={{@user.name}} />
            <a.Fallback class="rounded-lg">CN</a.Fallback>
          </Avatar>
          <div class="grid flex-1 text-left text-sm leading-tight">
            <span class="truncate font-medium">{{@user.name}}</span>
            <span class="truncate text-xs">{{@user.email}}</span>
          </div>
          <Icon @icon={{ChevronsUpDown}} class="ml-auto size-4" />
        </@sidebar.MenuButton>
        <m.Content
          class="w-(--radix-dropdown-menu-trigger-width) min-w-56 rounded-lg"
          @side={{if @sidebar.isMobile "bottom" "right"}}
          @align="end"
          @sideOffset={{4}}
        >
          <m.Group>
            <m.Label class="p-0 font-normal">
              <div class="flex items-center gap-2 px-1 py-1.5 text-left text-sm">
                <Avatar class="h-8 w-8 rounded-lg" as |a|>
                  <a.Image @src={{@user.avatar}} alt={{@user.name}} />
                  <a.Fallback class="rounded-lg">CN</a.Fallback>
                </Avatar>
                <div class="grid flex-1 text-left text-sm leading-tight">
                  <span class="truncate font-medium">{{@user.name}}</span>
                  <span class="truncate text-xs">{{@user.email}}</span>
                </div>
              </div>
            </m.Label>
          </m.Group>
          <m.Separator />
          <m.Group>
            <m.Item>
              <Icon @icon={{Sparkles}} />
              Upgrade to Pro
            </m.Item>
          </m.Group>
          <m.Separator />
          <m.Group>
            <m.Item>
              <Icon @icon={{BadgeCheck}} />
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
          <m.Group>
            <m.Item>
              <Icon @icon={{LogOut}} />
              Log out
            </m.Item>
          </m.Group>
        </m.Content>
      </DropdownMenu>
    </@sidebar.MenuItem>
  </@sidebar.Menu>
</template>

<template>
  <SidebarProvider as |sidebar|>
    <sidebar.Sidebar @collapsible="icon">
      <sidebar.Header>
        <TeamSwitcher @sidebar={{sidebar}} @teams={{data.teams}} />
      </sidebar.Header>
      <sidebar.Content>
        <NavMain @sidebar={{sidebar}} @items={{data.navMain}} />
        <NavProjects @sidebar={{sidebar}} @projects={{data.projects}} />
      </sidebar.Content>
      <sidebar.Footer>
        <NavUser @sidebar={{sidebar}} @user={{data.user}} />
      </sidebar.Footer>
      <sidebar.Rail />
    </sidebar.Sidebar>
    <sidebar.Inset>
      <header
        class="flex h-16 shrink-0 items-center gap-2 transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-12"
      >
        <div class="flex items-center gap-2 px-4">
          <sidebar.Trigger class="-ml-1" />
        </div>
      </header>
    </sidebar.Inset>
  </SidebarProvider>
</template>
