import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import {
  Bell,
  CreditCard,
  Download,
  Eye,
  File,
  FileCode,
  FileText,
  Folder,
  FolderOpen,
  FolderSearch,
  HelpCircle,
  Keyboard,
  Languages,
  Layout,
  LogOut,
  Mail,
  Monitor,
  Moon,
  MoreHorizontal,
  Palette,
  Save,
  Settings,
  Shield,
  Sun,
  User,
} from 'lucide'
import { Button, DropdownMenu, Icon } from '@ember-joinery/ember'

type Channel = 'email' | 'sms' | 'push'

export default class DropdownMenuComplex extends Component {
  @tracked notifications = { email: true, sms: false, push: true }
  @tracked theme = 'light'

  setNotification = (channel: Channel, checked: boolean) => {
    this.notifications = { ...this.notifications, [channel]: checked === true }
  }

  setTheme = (theme: string) => (this.theme = theme)

  <template>
    <DropdownMenu as |m|>
      <Button @variant="outline" {{m.trigger}}>Complex Menu</Button>
      <m.Content class="w-44">
        <m.Group>
          <m.Label>File</m.Label>
          <m.Item>
            <Icon @icon={{File}} />
            New File
            <m.Shortcut>⌘N</m.Shortcut>
          </m.Item>
          <m.Item>
            <Icon @icon={{Folder}} />
            New Folder
            <m.Shortcut>⇧⌘N</m.Shortcut>
          </m.Item>
          <m.Sub as |recent|>
            <recent.Trigger>
              <Icon @icon={{FolderOpen}} />
              Open Recent
            </recent.Trigger>
            <m.Portal>
              <recent.Content>
                <m.Group>
                  <m.Label>Recent Projects</m.Label>
                  <m.Item>
                    <Icon @icon={{FileCode}} />
                    Project Alpha
                  </m.Item>
                  <m.Item>
                    <Icon @icon={{FileCode}} />
                    Project Beta
                  </m.Item>
                  <m.Sub as |more|>
                    <more.Trigger>
                      <Icon @icon={{MoreHorizontal}} />
                      More Projects
                    </more.Trigger>
                    <m.Portal>
                      <more.Content>
                        <m.Item>
                          <Icon @icon={{FileCode}} />
                          Project Gamma
                        </m.Item>
                        <m.Item>
                          <Icon @icon={{FileCode}} />
                          Project Delta
                        </m.Item>
                      </more.Content>
                    </m.Portal>
                  </m.Sub>
                </m.Group>
                <m.Separator />
                <m.Group>
                  <m.Item>
                    <Icon @icon={{FolderSearch}} />
                    Browse...
                  </m.Item>
                </m.Group>
              </recent.Content>
            </m.Portal>
          </m.Sub>
          <m.Separator />
          <m.Item>
            <Icon @icon={{Save}} />
            Save
            <m.Shortcut>⌘S</m.Shortcut>
          </m.Item>
          <m.Item>
            <Icon @icon={{Download}} />
            Export
            <m.Shortcut>⇧⌘E</m.Shortcut>
          </m.Item>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Label>View</m.Label>
          <m.CheckboxItem
            @checked={{this.notifications.email}}
            @onCheckedChange={{fn this.setNotification "email"}}
          >
            <Icon @icon={{Eye}} />
            Show Sidebar
          </m.CheckboxItem>
          <m.CheckboxItem
            @checked={{this.notifications.sms}}
            @onCheckedChange={{fn this.setNotification "sms"}}
          >
            <Icon @icon={{Layout}} />
            Show Status Bar
          </m.CheckboxItem>
          <m.Sub as |theme|>
            <theme.Trigger>
              <Icon @icon={{Palette}} />
              Theme
            </theme.Trigger>
            <m.Portal>
              <theme.Content>
                <m.Group>
                  <m.Label>Appearance</m.Label>
                  <m.RadioGroup @value={{this.theme}} @onValueChange={{this.setTheme}} as |g|>
                    <g.Item @value="light">
                      <Icon @icon={{Sun}} />
                      Light
                    </g.Item>
                    <g.Item @value="dark">
                      <Icon @icon={{Moon}} />
                      Dark
                    </g.Item>
                    <g.Item @value="system">
                      <Icon @icon={{Monitor}} />
                      System
                    </g.Item>
                  </m.RadioGroup>
                </m.Group>
              </theme.Content>
            </m.Portal>
          </m.Sub>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Label>Account</m.Label>
          <m.Item>
            <Icon @icon={{User}} />
            Profile
            <m.Shortcut>⇧⌘P</m.Shortcut>
          </m.Item>
          <m.Item>
            <Icon @icon={{CreditCard}} />
            Billing
          </m.Item>
          <m.Sub as |settings|>
            <settings.Trigger>
              <Icon @icon={{Settings}} />
              Settings
            </settings.Trigger>
            <m.Portal>
              <settings.Content>
                <m.Group>
                  <m.Label>Preferences</m.Label>
                  <m.Item>
                    <Icon @icon={{Keyboard}} />
                    Keyboard Shortcuts
                  </m.Item>
                  <m.Item>
                    <Icon @icon={{Languages}} />
                    Language
                  </m.Item>
                  <m.Sub as |types|>
                    <types.Trigger>
                      <Icon @icon={{Bell}} />
                      Notifications
                    </types.Trigger>
                    <m.Portal>
                      <types.Content>
                        <m.Group>
                          <m.Label>
                            Notification Types
                          </m.Label>
                          <m.CheckboxItem
                            @checked={{this.notifications.push}}
                            @onCheckedChange={{fn this.setNotification "push"}}
                          >
                            <Icon @icon={{Bell}} />
                            Push Notifications
                          </m.CheckboxItem>
                          <m.CheckboxItem
                            @checked={{this.notifications.email}}
                            @onCheckedChange={{fn this.setNotification "email"}}
                          >
                            <Icon @icon={{Mail}} />
                            Email Notifications
                          </m.CheckboxItem>
                        </m.Group>
                      </types.Content>
                    </m.Portal>
                  </m.Sub>
                </m.Group>
                <m.Separator />
                <m.Group>
                  <m.Item>
                    <Icon @icon={{Shield}} />
                    Privacy & Security
                  </m.Item>
                </m.Group>
              </settings.Content>
            </m.Portal>
          </m.Sub>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Item>
            <Icon @icon={{HelpCircle}} />
            Help & Support
          </m.Item>
          <m.Item>
            <Icon @icon={{FileText}} />
            Documentation
          </m.Item>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Item @variant="destructive">
            <Icon @icon={{LogOut}} />
            Sign Out
            <m.Shortcut>⇧⌘Q</m.Shortcut>
          </m.Item>
        </m.Group>
      </m.Content>
    </DropdownMenu>
  </template>
}
