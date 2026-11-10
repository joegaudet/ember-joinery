import type { TOC } from '@ember/component/template-only'
import {
  Camera,
  ChartBar,
  CircleHelp,
  Command,
  Database,
  File,
  FileChartColumn,
  FileText,
  Folder,
  LayoutDashboard,
  List,
  Search,
  Settings2,
  Users,
} from 'lucide'
import { Icon, type SidebarBlockParams, type SidebarVariant } from '@ember-joinery/ember'
import NavDocuments from './nav-documents.gts'
import NavMain from './nav-main.gts'
import NavSecondary from './nav-secondary.gts'
import NavUser from './nav-user.gts'

// The guide's dashboard-01 block (docs-app/app/examples/dashboard-01), as the demo copies it
// in: Settings routes to the settings dialog.
// Upstream's IconPlaceholder draws each icon from the icon library its theme picks; Joinery's
// icons are lucide's, so each is the placeholder's `lucide` icon.
const data = {
  user: {
    name: 'shadcn',
    email: 'm@example.com',
    avatar: '/avatars/shadcn.jpg',
  },
  navMain: [
    {
      title: 'Dashboard',
      url: '#',
      icon: LayoutDashboard,
    },
    {
      title: 'Lifecycle',
      url: '#',
      icon: List,
    },
    {
      title: 'Analytics',
      url: '#',
      icon: ChartBar,
    },
    {
      title: 'Projects',
      url: '#',
      icon: Folder,
    },
    {
      title: 'Team',
      url: '#',
      icon: Users,
    },
  ],
  navClouds: [
    {
      title: 'Capture',
      icon: Camera,
      isActive: true,
      url: '#',
      items: [
        {
          title: 'Active Proposals',
          url: '#',
        },
        {
          title: 'Archived',
          url: '#',
        },
      ],
    },
    {
      title: 'Proposal',
      icon: FileText,
      url: '#',
      items: [
        {
          title: 'Active Proposals',
          url: '#',
        },
        {
          title: 'Archived',
          url: '#',
        },
      ],
    },
    {
      title: 'Prompts',
      icon: FileText,
      url: '#',
      items: [
        {
          title: 'Active Proposals',
          url: '#',
        },
        {
          title: 'Archived',
          url: '#',
        },
      ],
    },
  ],
  navSecondary: [
    {
      title: 'Settings',
      url: '#',
      icon: Settings2,
      // The demo's: Settings opens the settings dialog, at /settings.
      route: 'preferences',
    },
    {
      title: 'Get Help',
      url: '#',
      icon: CircleHelp,
    },
    {
      title: 'Search',
      url: '#',
      icon: Search,
    },
  ],
  documents: [
    {
      name: 'Data Library',
      url: '#',
      icon: Database,
    },
    {
      name: 'Reports',
      url: '#',
      icon: FileChartColumn,
    },
    {
      name: 'Word Assistant',
      url: '#',
      icon: File,
    },
  ],
}

// Upstream spreads its props on the Sidebar (the page passes variant="inset"): here @variant
// and a caller's attributes.
const AppSidebar: TOC<{
  Args: { sidebar: SidebarBlockParams; variant?: SidebarVariant }
  Element: HTMLDivElement
}> = <template>
  <@sidebar.Sidebar @collapsible="offcanvas" @variant={{@variant}} ...attributes>
    <@sidebar.Header>
      <@sidebar.Menu>
        <@sidebar.MenuItem>
          <@sidebar.MenuButton @as="a" href="#" class="data-[slot=sidebar-menu-button]:p-1.5!">
            <Icon @icon={{Command}} class="size-5!" />
            <span class="text-base font-semibold">Acme Inc.</span>
          </@sidebar.MenuButton>
        </@sidebar.MenuItem>
      </@sidebar.Menu>
    </@sidebar.Header>
    <@sidebar.Content>
      <NavMain @sidebar={{@sidebar}} @items={{data.navMain}} />
      <NavDocuments @sidebar={{@sidebar}} @items={{data.documents}} />
      <NavSecondary @sidebar={{@sidebar}} @items={{data.navSecondary}} class="mt-auto" />
    </@sidebar.Content>
    <@sidebar.Footer>
      <NavUser @sidebar={{@sidebar}} @user={{data.user}} />
    </@sidebar.Footer>
  </@sidebar.Sidebar>
</template>

export default AppSidebar
