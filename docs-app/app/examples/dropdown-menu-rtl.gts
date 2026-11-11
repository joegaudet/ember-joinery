import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { CreditCard, Settings, User } from 'lucide'
import { Button, DropdownMenu, Icon } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  open: 'افتح القائمة',
  account: 'الحساب',
  profile: 'الملف الشخصي',
  billing: 'الفوترة',
  settings: 'الإعدادات',
  logout: 'تسجيل الخروج',
  team: 'الفريق',
  inviteUsers: 'دعوة المستخدمين',
  email: 'البريد الإلكتروني',
  message: 'رسالة',
  more: 'المزيد',
  calendar: 'تقويم',
  chat: 'دردشة',
  webhook: 'خطاف ويب',
  advanced: 'متقدم...',
  newTeam: 'فريق جديد',
  view: 'عرض',
  statusBar: 'شريط الحالة',
  activityBar: 'شريط النشاط',
  panel: 'اللوحة',
  position: 'الموضع',
  top: 'أعلى',
  bottom: 'أسفل',
  right: 'يمين',
  left: 'يسار',
}

export default class DropdownMenuRtl extends Component {
  @tracked showStatusBar = true
  @tracked showActivityBar = false
  @tracked showPanel = false
  @tracked position = 'bottom'

  setShowStatusBar = (checked: boolean) => (this.showStatusBar = checked)
  setShowActivityBar = (checked: boolean) => (this.showActivityBar = checked)
  setShowPanel = (checked: boolean) => (this.showPanel = checked)
  setPosition = (position: string) => (this.position = position)

  <template>
    <DropdownMenu as |m|>
      <Button @variant="outline" {{m.trigger}}>{{t.open}}</Button>
      <m.Content class="w-36">
        <m.Group>
          <m.Sub as |account|>
            <account.Trigger>{{t.account}}</account.Trigger>
            <m.Portal>
              <account.Content>
                <m.Group>
                  <m.Item>
                    <Icon @icon={{User}} />
                    {{t.profile}}
                  </m.Item>
                  <m.Item>
                    <Icon @icon={{CreditCard}} />
                    {{t.billing}}
                  </m.Item>
                  <m.Item>
                    <Icon @icon={{Settings}} />
                    {{t.settings}}
                  </m.Item>
                </m.Group>
              </account.Content>
            </m.Portal>
          </m.Sub>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Label>{{t.team}}</m.Label>
          <m.Item>{{t.team}}</m.Item>
          <m.Sub as |invite|>
            <invite.Trigger>{{t.inviteUsers}}</invite.Trigger>
            <m.Portal>
              <invite.Content>
                <m.Item>{{t.email}}</m.Item>
                <m.Item>{{t.message}}</m.Item>
                <m.Sub as |more|>
                  <more.Trigger>{{t.more}}</more.Trigger>
                  <m.Portal>
                    <more.Content>
                      <m.Item>{{t.calendar}}</m.Item>
                      <m.Item>{{t.chat}}</m.Item>
                      <m.Separator />
                      <m.Item>{{t.webhook}}</m.Item>
                    </more.Content>
                  </m.Portal>
                </m.Sub>
                <m.Separator />
                <m.Item>{{t.advanced}}</m.Item>
              </invite.Content>
            </m.Portal>
          </m.Sub>
          <m.Item>
            {{t.newTeam}}
            <m.Shortcut>⌘+T</m.Shortcut>
          </m.Item>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Label>{{t.view}}</m.Label>
          <m.CheckboxItem
            @checked={{this.showStatusBar}}
            @onCheckedChange={{this.setShowStatusBar}}
          >
            {{t.statusBar}}
          </m.CheckboxItem>
          <m.CheckboxItem
            @checked={{this.showActivityBar}}
            @onCheckedChange={{this.setShowActivityBar}}
          >
            {{t.activityBar}}
          </m.CheckboxItem>
          <m.CheckboxItem @checked={{this.showPanel}} @onCheckedChange={{this.setShowPanel}}>
            {{t.panel}}
          </m.CheckboxItem>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Label>{{t.position}}</m.Label>
          <m.RadioGroup @value={{this.position}} @onValueChange={{this.setPosition}} as |g|>
            <g.Item @value="top">{{t.top}}</g.Item>
            <g.Item @value="bottom">
              {{t.bottom}}
            </g.Item>
            <g.Item @value="right">
              {{t.right}}
            </g.Item>
            <g.Item @value="left">{{t.left}}</g.Item>
          </m.RadioGroup>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Item @variant="destructive">{{t.logout}}</m.Item>
        </m.Group>
      </m.Content>
    </DropdownMenu>
  </template>
}
