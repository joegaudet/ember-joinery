import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { Bell, Mail, MessageSquare } from 'lucide'
import { Button, DropdownMenu, Icon } from '@ember-joinery/ember'

type Channel = 'email' | 'sms' | 'push'

export default class DropdownMenuCheckboxesIcons extends Component {
  @tracked notifications = { email: true, sms: false, push: true }

  setNotification = (channel: Channel, checked: boolean) => {
    this.notifications = { ...this.notifications, [channel]: checked === true }
  }

  <template>
    <DropdownMenu as |m|>
      <Button @variant="outline" {{m.trigger}}>Notifications</Button>
      <m.Content class="w-48">
        <m.Group>
          <m.Label>Notification Preferences</m.Label>
          <m.CheckboxItem
            @checked={{this.notifications.email}}
            @onCheckedChange={{fn this.setNotification "email"}}
          >
            <Icon @icon={{Mail}} />
            Email notifications
          </m.CheckboxItem>
          <m.CheckboxItem
            @checked={{this.notifications.sms}}
            @onCheckedChange={{fn this.setNotification "sms"}}
          >
            <Icon @icon={{MessageSquare}} />
            SMS notifications
          </m.CheckboxItem>
          <m.CheckboxItem
            @checked={{this.notifications.push}}
            @onCheckedChange={{fn this.setNotification "push"}}
          >
            <Icon @icon={{Bell}} />
            Push notifications
          </m.CheckboxItem>
        </m.Group>
      </m.Content>
    </DropdownMenu>
  </template>
}
