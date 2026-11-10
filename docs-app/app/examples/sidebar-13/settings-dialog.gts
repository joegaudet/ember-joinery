import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
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
import { Breadcrumb, Button, Dialog, Icon, SidebarProvider } from '@ember-joinery/ember'

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

const isActive = (name: string) => name === 'Messages & media'
const PLACEHOLDERS = Array.from({ length: 10 }, (_, i) => i)

export default class SettingsDialog extends Component {
  // Upstream's useState(true): the dialog starts open.
  @tracked open = true

  setOpen = (open: boolean) => (this.open = open)

  <template>
    <Dialog @open={{this.open}} @onOpenChange={{this.setOpen}} as |d|>
      <Button @size="sm" {{d.trigger}}>Open Dialog</Button>
      <d.Content class="overflow-hidden p-0 md:max-h-[500px] md:max-w-[700px] lg:max-w-[800px]">
        <d.Title class="sr-only">Settings</d.Title>
        <d.Description class="sr-only">
          Customize your settings here.
        </d.Description>
        <SidebarProvider class="items-start" as |sidebar|>
          <sidebar.Sidebar @collapsible="none" class="hidden md:flex">
            <sidebar.Content>
              <sidebar.Group>
                <sidebar.GroupContent>
                  <sidebar.Menu>
                    {{#each data.nav as |item|}}
                      <sidebar.MenuItem>
                        <sidebar.MenuButton @as="a" href="#" @isActive={{isActive item.name}}>
                          <Icon @icon={{item.icon}} />
                          <span>{{item.name}}</span>
                        </sidebar.MenuButton>
                      </sidebar.MenuItem>
                    {{/each}}
                  </sidebar.Menu>
                </sidebar.GroupContent>
              </sidebar.Group>
            </sidebar.Content>
          </sidebar.Sidebar>
          <main class="flex h-[480px] flex-1 flex-col overflow-hidden">
            <header
              class="flex h-16 shrink-0 items-center gap-2 transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-12"
            >
              <div class="flex items-center gap-2 px-4">
                <Breadcrumb as |b|>
                  <b.List>
                    <b.Item class="hidden md:block">
                      <b.Link href="#">Settings</b.Link>
                    </b.Item>
                    <b.Separator class="hidden md:block" />
                    <b.Item>
                      <b.Page>Messages & media</b.Page>
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
          </main>
        </SidebarProvider>
      </d.Content>
    </Dialog>
  </template>
}
