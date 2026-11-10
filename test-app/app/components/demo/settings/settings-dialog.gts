import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { LinkTo } from '@ember/routing'
import { service } from '@ember/service'
import type RouterService from '@ember/routing/router-service'
import {
  Bell,
  Check,
  Globe,
  House,
  Keyboard,
  Link,
  Lock,
  Menu,
  MessageCircle,
  Paintbrush,
  Settings,
  Video,
} from 'lucide'
import { Breadcrumb, Dialog, Icon, SidebarProvider } from '@ember-joinery/ember'

const data = {
  nav: [
    { name: 'Notifications', icon: Bell },
    { name: 'Navigation', icon: Menu },
    { name: 'Home', icon: House },
    { name: 'Appearance', icon: Paintbrush },
    { name: 'Messages & media', icon: MessageCircle },
    { name: 'Language & region', icon: Globe },
    { name: 'Accessibility', icon: Keyboard },
    { name: 'Mark as read', icon: Check },
    { name: 'Audio & video', icon: Video },
    { name: 'Connected accounts', icon: Link },
    { name: 'Privacy & visibility', icon: Lock },
    { name: 'Advanced', icon: Settings },
  ],
}

const PLACEHOLDERS = Array.from({ length: 10 }, (_, i) => i)

/**
 * The guide's settings block (docs-app/app/examples/sidebar-13), as the demo copies it in. The
 * /settings route opens it over the dashboard; each section is a link to /settings?section=…,
 * and the one it names is the active one and the breadcrumb's page (upstream's "Messages &
 * media" until one is picked); closing the dialog goes back to the dashboard. Upstream's
 * trigger button stays out: the route opens the dialog.
 */
export default class SettingsDialog extends Component<{ Args: { section?: string | null } }> {
  @service declare router: RouterService

  get active(): string {
    return this.args.section || 'Messages & media'
  }

  isActive = (name: string) => name === this.active

  setOpen = (open: boolean) => {
    if (!open) void this.router.transitionTo('index')
  }

  <template>
    <Dialog @open={{true}} @onOpenChange={{this.setOpen}} @name="settings" as |d|>
      <d.Content class="overflow-hidden p-0 md:max-h-[500px] md:max-w-[700px] lg:max-w-[800px]">
        <d.Title class="sr-only">Settings</d.Title>
        <d.Description class="sr-only">
          Customize your settings here.
        </d.Description>
        {{! The demo's: the dashboard's provider takes ⌘B and keeps its open state in the
            cookie, so this one, whose sidebar doesn't collapse, takes neither. }}
        <SidebarProvider
          class="items-start"
          @keyboardShortcut={{false}}
          @cookieName={{false}}
          as |sidebar|
        >
          <sidebar.Sidebar @collapsible="none" class="hidden md:flex">
            <sidebar.Content>
              <sidebar.Group>
                <sidebar.GroupContent>
                  <sidebar.Menu>
                    {{#each data.nav as |item|}}
                      <sidebar.MenuItem>
                        <LinkTo
                          @route="preferences"
                          @query={{hash section=item.name}}
                          {{sidebar.menuButton isActive=(this.isActive item.name)}}
                        >
                          <Icon @icon={{item.icon}} />
                          <span>{{item.name}}</span>
                        </LinkTo>
                      </sidebar.MenuItem>
                    {{/each}}
                  </sidebar.Menu>
                </sidebar.GroupContent>
              </sidebar.Group>
            </sidebar.Content>
          </sidebar.Sidebar>
          {{! The demo's: the dashboard behind the dialog is the page's <main> (the sidebar's
              inset), so the panel is a <div>, where upstream's, alone on its page, is a main. }}
          <div class="flex h-[480px] flex-1 flex-col overflow-hidden">
            <header
              class="flex h-16 shrink-0 items-center gap-2 transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-12"
            >
              <div class="flex items-center gap-2 px-4">
                <Breadcrumb as |b|>
                  <b.List>
                    <b.Item class="hidden md:block">
                      <LinkTo @route="preferences" @query={{hash section=null}} {{b.link}}>
                        Settings
                      </LinkTo>
                    </b.Item>
                    <b.Separator class="hidden md:block" />
                    <b.Item>
                      <b.Page>{{this.active}}</b.Page>
                    </b.Item>
                  </b.List>
                </Breadcrumb>
              </div>
            </header>
            {{! Upstream's scrolling region takes no focus, so a keyboard can't scroll it;
                this one can (tabindex="0"), which the accessibility audit asks for. }}
            <div class="flex flex-1 flex-col gap-4 overflow-y-auto p-4 pt-0" tabindex="0">
              {{#each PLACEHOLDERS}}
                <div class="aspect-video max-w-3xl rounded-xl bg-muted/50" />
              {{/each}}
            </div>
          </div>
        </SidebarProvider>
      </d.Content>
    </Dialog>
  </template>
}
