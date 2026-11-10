import type { TOC } from '@ember/component/template-only'
import {
  BadgeCheck,
  Bell,
  BookOpen,
  Bot,
  ChevronRight,
  ChevronsUpDown,
  CreditCard,
  Folder,
  Forward,
  Frame,
  GalleryVerticalEnd,
  LogOut,
  Map,
  MoreHorizontal,
  PieChart,
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

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English, and
// a language picker, which the guide's frame doesn't have). Its direction is the frame's.
const t = {
  teamName: 'شركة أكمي',
  teamPlan: 'المؤسسة',
  platform: 'المنصة',
  projects: 'المشاريع',
  viewProject: 'عرض المشروع',
  shareProject: 'مشاركة المشروع',
  deleteProject: 'حذف المشروع',
  more: 'المزيد',
  upgradeToPro: 'ترقية إلى Pro',
  account: 'الحساب',
  billing: 'الفوترة',
  notifications: 'الإشعارات',
  logOut: 'تسجيل الخروج',
  playground: 'ملعب',
  history: 'السجل',
  starred: 'المميز',
  settings: 'الإعدادات',
  models: 'النماذج',
  genesis: 'جينيسيس',
  explorer: 'إكسبلورر',
  quantum: 'كوانتوم',
  documentation: 'التوثيق',
  introduction: 'مقدمة',
  getStarted: 'ابدأ',
  tutorials: 'الدروس',
  changelog: 'سجل التغييرات',
  general: 'عام',
  team: 'الفريق',
  limits: 'الحدود',
  designEngineering: 'هندسة التصميم',
  salesMarketing: 'المبيعات والتسويق',
  travel: 'السفر',
}

const dir = 'rtl'

const navMain = [
  {
    title: t.playground,
    url: '#',
    icon: SquareTerminal,
    isActive: true,
    items: [
      { title: t.history, url: '#' },
      { title: t.starred, url: '#' },
      { title: t.settings, url: '#' },
    ],
  },
  {
    title: t.models,
    url: '#',
    icon: Bot,
    items: [
      { title: t.genesis, url: '#' },
      { title: t.explorer, url: '#' },
      { title: t.quantum, url: '#' },
    ],
  },
  {
    title: t.documentation,
    url: '#',
    icon: BookOpen,
    items: [
      { title: t.introduction, url: '#' },
      { title: t.getStarted, url: '#' },
      { title: t.tutorials, url: '#' },
      { title: t.changelog, url: '#' },
    ],
  },
  {
    title: t.settings,
    url: '#',
    icon: Settings2,
    items: [
      { title: t.general, url: '#' },
      { title: t.team, url: '#' },
      { title: t.billing, url: '#' },
      { title: t.limits, url: '#' },
    ],
  },
]

const projects = [
  { name: t.designEngineering, url: '#', icon: Frame },
  { name: t.salesMarketing, url: '#', icon: PieChart },
  { name: t.travel, url: '#', icon: Map },
]

const user = {
  name: 'shadcn',
  email: 'm@example.com',
  avatar: '/avatars/shadcn.jpg',
}

interface Props {
  sidebar: SidebarBlockParams
  navMain: Array<{
    title: string
    url: string
    icon?: IconNode
    isActive?: boolean
    items?: Array<{ title: string; url: string }>
  }>
  projects: Array<{ name: string; url: string; icon: IconNode }>
  user: { name: string; email: string; avatar: string }
}

// Upstream's SidebarContentInner, which calls useSidebar(): here it takes what the
// SidebarProvider yields. The Collapsible asChild is the menu item (@as="li" and
// sidebar.menuItem), and each asChild trigger is the menu button (m.trigger, c.trigger).
const SidebarContentInner: TOC<{ Args: Props }> = <template>
  <@sidebar.Sidebar @collapsible="icon" @side="right" dir={{dir}}>
    <@sidebar.Header>
      <@sidebar.Menu>
        <@sidebar.MenuItem>
          <@sidebar.MenuButton @size="lg" @as="a" href="#">
            <div
              class="flex aspect-square size-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground"
            >
              <Icon @icon={{GalleryVerticalEnd}} class="size-4" />
            </div>
            <div class="flex flex-col gap-0.5 leading-none">
              <span class="font-medium">{{t.teamName}}</span>
              <span class="">{{t.teamPlan}}</span>
            </div>
          </@sidebar.MenuButton>
        </@sidebar.MenuItem>
      </@sidebar.Menu>
    </@sidebar.Header>
    <@sidebar.Content>
      <@sidebar.Group>
        <@sidebar.GroupLabel>{{t.platform}}</@sidebar.GroupLabel>
        <@sidebar.Menu>
          {{#each @navMain as |item|}}
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
                  class="ms-auto transition-transform duration-200 group-data-[state=open]/collapsible:rotate-90 rtl:rotate-180 rtl:group-data-[state=open]/collapsible:rotate-90"
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
      <@sidebar.Group class="group-data-[collapsible=icon]:hidden">
        <@sidebar.GroupLabel>{{t.projects}}</@sidebar.GroupLabel>
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
                  <span class="sr-only">{{t.more}}</span>
                </@sidebar.MenuAction>
                <m.Content
                  class="w-48 rounded-lg"
                  @side={{if @sidebar.isMobile "bottom" "right"}}
                  @align={{if @sidebar.isMobile "end" "start"}}
                >
                  <m.Group>
                    <m.Item>
                      <Icon @icon={{Folder}} class="text-muted-foreground" />
                      <span>{{t.viewProject}}</span>
                    </m.Item>
                    <m.Item>
                      <Icon @icon={{Forward}} class="text-muted-foreground" />
                      <span>{{t.shareProject}}</span>
                    </m.Item>
                  </m.Group>
                  <m.Separator />
                  <m.Group>
                    <m.Item>
                      <Icon @icon={{Trash2}} class="text-muted-foreground" />
                      <span>{{t.deleteProject}}</span>
                    </m.Item>
                  </m.Group>
                </m.Content>
              </DropdownMenu>
            </@sidebar.MenuItem>
          {{/each}}
          <@sidebar.MenuItem>
            <@sidebar.MenuButton class="text-sidebar-foreground/70">
              <Icon @icon={{MoreHorizontal}} class="text-sidebar-foreground/70" />
              <span>{{t.more}}</span>
            </@sidebar.MenuButton>
          </@sidebar.MenuItem>
        </@sidebar.Menu>
      </@sidebar.Group>
    </@sidebar.Content>
    <@sidebar.Footer>
      <@sidebar.Menu>
        <@sidebar.MenuItem>
          <DropdownMenu as |m|>
            <@sidebar.MenuButton
              @size="lg"
              class="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
              {{m.trigger}}
            >
              <Avatar class="rounded-lg" as |a|>
                <a.Image @src={{@user.avatar}} alt={{@user.name}} />
                <a.Fallback class="rounded-lg">CN</a.Fallback>
              </Avatar>
              <div class="grid flex-1 text-start text-sm leading-tight">
                <span class="truncate font-medium">{{@user.name}}</span>
                <span class="truncate text-xs">{{@user.email}}</span>
              </div>
              <Icon @icon={{ChevronsUpDown}} class="ms-auto size-4" />
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
                    <Avatar as |a|>
                      <a.Image @src={{@user.avatar}} alt={{@user.name}} />
                      <a.Fallback class="rounded-lg">
                        CN
                      </a.Fallback>
                    </Avatar>
                    <div class="grid flex-1 text-start text-sm leading-tight">
                      <span class="truncate font-medium">
                        {{@user.name}}
                      </span>
                      <span class="truncate text-xs">{{@user.email}}</span>
                    </div>
                  </div>
                </m.Label>
              </m.Group>
              <m.Separator />
              <m.Group>
                <m.Item>
                  <Icon @icon={{Sparkles}} />
                  {{t.upgradeToPro}}
                </m.Item>
              </m.Group>
              <m.Separator />
              <m.Group>
                <m.Item>
                  <Icon @icon={{BadgeCheck}} />
                  {{t.account}}
                </m.Item>
                <m.Item>
                  <Icon @icon={{CreditCard}} />
                  {{t.billing}}
                </m.Item>
                <m.Item>
                  <Icon @icon={{Bell}} />
                  {{t.notifications}}
                </m.Item>
              </m.Group>
              <m.Separator />
              <m.Group>
                <m.Item>
                  <Icon @icon={{LogOut}} />
                  {{t.logOut}}
                </m.Item>
              </m.Group>
            </m.Content>
          </DropdownMenu>
        </@sidebar.MenuItem>
      </@sidebar.Menu>
    </@sidebar.Footer>
    <@sidebar.Rail />
  </@sidebar.Sidebar>
  <@sidebar.Inset>
    <header
      class="flex h-16 shrink-0 items-center gap-2 transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-12"
      dir={{dir}}
    >
      <div class="flex items-center gap-2 px-4">
        <@sidebar.Trigger class="-ml-1" />
      </div>
    </header>
  </@sidebar.Inset>
</template>

<template>
  <SidebarProvider as |sidebar|>
    <SidebarContentInner
      @sidebar={{sidebar}}
      @navMain={{navMain}}
      @projects={{projects}}
      @user={{user}}
    />
  </SidebarProvider>
</template>
