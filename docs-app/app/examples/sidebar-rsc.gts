import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { Frame, LifeBuoy, Map, PieChart, Send } from 'lucide'
import { load } from '@ember-joinery/primitives/load'
import { Icon, SidebarProvider, type SidebarBlockParams } from '@ember-joinery/ember'

const projects = [
  {
    name: 'Design Engineering',
    url: '#',
    icon: Frame,
    badge: '24',
  },
  {
    name: 'Sales & Marketing',
    url: '#',
    icon: PieChart,
    badge: '12',
  },
  {
    name: 'Travel',
    url: '#',
    icon: Map,
    badge: '3',
  },
  {
    name: 'Support',
    url: '#',
    icon: LifeBuoy,
    badge: '21',
  },
  {
    name: 'Feedback',
    url: '#',
    icon: Send,
    badge: '8',
  },
]

// Dummy fetch function.
async function fetchProjects() {
  await new Promise(resolve => setTimeout(resolve, 3000))
  return projects
}

interface NavSignature {
  Args: { sidebar: SidebarBlockParams }
}

const five = Array.from({ length: 5 })

const NavProjectsSkeleton: TOC<NavSignature> = <template>
  <@sidebar.Menu>
    {{#each five}}
      <@sidebar.MenuItem>
        <@sidebar.MenuSkeleton @showIcon={{true}} />
      </@sidebar.MenuItem>
    {{/each}}
  </@sidebar.Menu>
</template>

/**
 * Upstream's NavProjects is a React Server Component that awaits fetchProjects() inside a
 * Suspense boundary. Here `load()` from @ember-joinery/primitives/load waits for it: its
 * `<:loading>` block is the Suspense fallback.
 */
const navProjects = () =>
  load<NavSignature>(async () => {
    const projects = await fetchProjects()
    const NavProjects: TOC<NavSignature> = <template>
      <@sidebar.Menu>
        {{#each projects as |project|}}
          <@sidebar.MenuItem>
            <@sidebar.MenuButton @as="a" href={{project.url}}>
              <Icon @icon={{project.icon}} />
              <span>{{project.name}}</span>
            </@sidebar.MenuButton>
          </@sidebar.MenuItem>
        {{/each}}
      </@sidebar.Menu>
    </template>
    return NavProjects
  })

export default class AppSidebar extends Component {
  // One fetch for each sidebar rendered, as a server component fetches on each request.
  NavProjects = navProjects()

  <template>
    <SidebarProvider as |sidebar|>
      <sidebar.Sidebar>
        <sidebar.Content>
          <sidebar.Group>
            <sidebar.GroupLabel>Projects</sidebar.GroupLabel>
            <sidebar.GroupContent>
              <this.NavProjects>
                <:loading><NavProjectsSkeleton @sidebar={{sidebar}} /></:loading>
                <:error as |error|>{{error.reason}}</:error>
                <:success as |NavProjects|><NavProjects @sidebar={{sidebar}} /></:success>
              </this.NavProjects>
            </sidebar.GroupContent>
          </sidebar.Group>
        </sidebar.Content>
      </sidebar.Sidebar>
    </SidebarProvider>
  </template>
}
