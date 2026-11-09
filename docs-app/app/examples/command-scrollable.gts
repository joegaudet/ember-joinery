import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import {
  Bell,
  Calculator,
  Calendar,
  ClipboardPaste,
  Code,
  Copy,
  CreditCard,
  FileText,
  Folder,
  FolderPlus,
  HelpCircle,
  Home,
  Image,
  Inbox,
  LayoutGrid,
  List,
  Plus,
  Scissors,
  Settings,
  Trash,
  User,
  ZoomIn,
  ZoomOut,
} from 'lucide'
import { Button, Command, CommandDialog, Icon } from '@ember-joinery/ember'

export default class CommandManyItems extends Component {
  @tracked open = false

  setOpen = (open: boolean) => (this.open = open)

  <template>
    <div class="flex flex-col gap-4">
      <Button @variant="outline" class="w-fit" {{on "click" (fn this.setOpen true)}}>
        Open Menu
      </Button>
      <CommandDialog @open={{this.open}} @onOpenChange={{this.setOpen}}>
        <Command as |c|>
          <c.Input placeholder="Type a command or search..." />
          <c.List>
            <c.Empty>No results found.</c.Empty>
            <c.Group @heading="Navigation">
              <c.Item>
                <Icon @icon={{Home}} />
                <span>Home</span>
                <c.Shortcut>⌘H</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{Inbox}} />
                <span>Inbox</span>
                <c.Shortcut>⌘I</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{FileText}} />
                <span>Documents</span>
                <c.Shortcut>⌘D</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{Folder}} />
                <span>Folders</span>
                <c.Shortcut>⌘F</c.Shortcut>
              </c.Item>
            </c.Group>
            <c.Separator />
            <c.Group @heading="Actions">
              <c.Item>
                <Icon @icon={{Plus}} />
                <span>New File</span>
                <c.Shortcut>⌘N</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{FolderPlus}} />
                <span>New Folder</span>
                <c.Shortcut>⇧⌘N</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{Copy}} />
                <span>Copy</span>
                <c.Shortcut>⌘C</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{Scissors}} />
                <span>Cut</span>
                <c.Shortcut>⌘X</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{ClipboardPaste}} />
                <span>Paste</span>
                <c.Shortcut>⌘V</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{Trash}} />
                <span>Delete</span>
                <c.Shortcut>⌫</c.Shortcut>
              </c.Item>
            </c.Group>
            <c.Separator />
            <c.Group @heading="View">
              <c.Item>
                <Icon @icon={{LayoutGrid}} />
                <span>Grid View</span>
              </c.Item>
              <c.Item>
                <Icon @icon={{List}} />
                <span>List View</span>
              </c.Item>
              <c.Item>
                <Icon @icon={{ZoomIn}} />
                <span>Zoom In</span>
                <c.Shortcut>⌘+</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{ZoomOut}} />
                <span>Zoom Out</span>
                <c.Shortcut>⌘-</c.Shortcut>
              </c.Item>
            </c.Group>
            <c.Separator />
            <c.Group @heading="Account">
              <c.Item>
                <Icon @icon={{User}} />
                <span>Profile</span>
                <c.Shortcut>⌘P</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{CreditCard}} />
                <span>Billing</span>
                <c.Shortcut>⌘B</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{Settings}} />
                <span>Settings</span>
                <c.Shortcut>⌘S</c.Shortcut>
              </c.Item>
              <c.Item>
                <Icon @icon={{Bell}} />
                <span>Notifications</span>
              </c.Item>
              <c.Item>
                <Icon @icon={{HelpCircle}} />
                <span>Help & Support</span>
              </c.Item>
            </c.Group>
            <c.Separator />
            <c.Group @heading="Tools">
              <c.Item>
                <Icon @icon={{Calculator}} />
                <span>Calculator</span>
              </c.Item>
              <c.Item>
                <Icon @icon={{Calendar}} />
                <span>Calendar</span>
              </c.Item>
              <c.Item>
                <Icon @icon={{Image}} />
                <span>Image Editor</span>
              </c.Item>
              <c.Item>
                <Icon @icon={{Code}} />
                <span>Code Editor</span>
              </c.Item>
            </c.Group>
          </c.List>
        </Command>
      </CommandDialog>
    </div>
  </template>
}
