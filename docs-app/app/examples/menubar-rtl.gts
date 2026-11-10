import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Menubar } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  file: 'ملف',
  newTab: 'علامة تبويب جديدة',
  newWindow: 'نافذة جديدة',
  newIncognitoWindow: 'نافذة التصفح المتخفي الجديدة',
  share: 'مشاركة',
  emailLink: 'رابط البريد الإلكتروني',
  messages: 'الرسائل',
  notes: 'الملاحظات',
  print: 'طباعة...',
  edit: 'تعديل',
  undo: 'تراجع',
  redo: 'إعادة',
  find: 'بحث',
  searchTheWeb: 'البحث على الويب',
  findItem: 'بحث...',
  findNext: 'البحث التالي',
  findPrevious: 'البحث السابق',
  cut: 'قص',
  copy: 'نسخ',
  paste: 'لصق',
  view: 'عرض',
  bookmarksBar: 'شريط الإشارات المرجعية',
  fullUrls: 'عناوين URL الكاملة',
  reload: 'إعادة تحميل',
  forceReload: 'إعادة تحميل قسري',
  toggleFullscreen: 'تبديل وضع ملء الشاشة',
  hideSidebar: 'إخفاء الشريط الجانبي',
  profiles: 'الملفات الشخصية',
  andy: 'Andy',
  benoit: 'Benoit',
  luis: 'Luis',
  editProfile: 'تعديل...',
  addProfile: 'إضافة ملف شخصي...',
}

export default class MenubarRtl extends Component {
  @tracked profile = 'benoit'

  setProfile = (profile: string) => (this.profile = profile)

  <template>
    <Menubar class="w-72" as |bar|>
      <bar.Menu as |m|>
        <m.Trigger>{{t.file}}</m.Trigger>
        <m.Content>
          <m.Group>
            <m.Item>
              {{t.newTab}}
              <m.Shortcut>⌘T</m.Shortcut>
            </m.Item>
            <m.Item>
              {{t.newWindow}}
              <m.Shortcut>⌘N</m.Shortcut>
            </m.Item>
            <m.Item @disabled={{true}}>{{t.newIncognitoWindow}}</m.Item>
          </m.Group>
          <m.Separator />
          <m.Group>
            <m.Sub as |s|>
              <s.Trigger>{{t.share}}</s.Trigger>
              <s.Content>
                <m.Group>
                  <m.Item>{{t.emailLink}}</m.Item>
                  <m.Item>{{t.messages}}</m.Item>
                  <m.Item>{{t.notes}}</m.Item>
                </m.Group>
              </s.Content>
            </m.Sub>
          </m.Group>
          <m.Separator />
          <m.Group>
            <m.Item>
              {{t.print}}
              <m.Shortcut>⌘P</m.Shortcut>
            </m.Item>
          </m.Group>
        </m.Content>
      </bar.Menu>
      <bar.Menu as |m|>
        <m.Trigger>{{t.edit}}</m.Trigger>
        <m.Content>
          <m.Group>
            <m.Item>
              {{t.undo}}
              <m.Shortcut>⌘Z</m.Shortcut>
            </m.Item>
            <m.Item>
              {{t.redo}}
              <m.Shortcut>⇧⌘Z</m.Shortcut>
            </m.Item>
          </m.Group>
          <m.Separator />
          <m.Group>
            <m.Sub as |s|>
              <s.Trigger>{{t.find}}</s.Trigger>
              <s.Content>
                <m.Group>
                  <m.Item>{{t.searchTheWeb}}</m.Item>
                </m.Group>
                <m.Separator />
                <m.Group>
                  <m.Item>{{t.findItem}}</m.Item>
                  <m.Item>{{t.findNext}}</m.Item>
                  <m.Item>{{t.findPrevious}}</m.Item>
                </m.Group>
              </s.Content>
            </m.Sub>
          </m.Group>
          <m.Separator />
          <m.Group>
            <m.Item>{{t.cut}}</m.Item>
            <m.Item>{{t.copy}}</m.Item>
            <m.Item>{{t.paste}}</m.Item>
          </m.Group>
        </m.Content>
      </bar.Menu>
      <bar.Menu as |m|>
        <m.Trigger>{{t.view}}</m.Trigger>
        <m.Content class="w-44">
          <m.Group>
            <m.CheckboxItem>{{t.bookmarksBar}}</m.CheckboxItem>
            <m.CheckboxItem @checked={{true}}>{{t.fullUrls}}</m.CheckboxItem>
          </m.Group>
          <m.Separator />
          <m.Group>
            <m.Item @inset={{true}}>
              {{t.reload}}
              <m.Shortcut>⌘R</m.Shortcut>
            </m.Item>
            <m.Item @disabled={{true}} @inset={{true}}>
              {{t.forceReload}}
              <m.Shortcut>⇧⌘R</m.Shortcut>
            </m.Item>
          </m.Group>
          <m.Separator />
          <m.Group>
            <m.Item @inset={{true}}>{{t.toggleFullscreen}}</m.Item>
          </m.Group>
          <m.Separator />
          <m.Group>
            <m.Item @inset={{true}}>{{t.hideSidebar}}</m.Item>
          </m.Group>
        </m.Content>
      </bar.Menu>
      <bar.Menu as |m|>
        <m.Trigger>{{t.profiles}}</m.Trigger>
        <m.Content>
          <m.RadioGroup @value={{this.profile}} @onValueChange={{this.setProfile}} as |g|>
            <g.Item @value="andy">{{t.andy}}</g.Item>
            <g.Item @value="benoit">{{t.benoit}}</g.Item>
            <g.Item @value="Luis">{{t.luis}}</g.Item>
          </m.RadioGroup>
          <m.Separator />
          <m.Group>
            <m.Item @inset={{true}}>{{t.editProfile}}</m.Item>
          </m.Group>
          <m.Separator />
          <m.Group>
            <m.Item @inset={{true}}>{{t.addProfile}}</m.Item>
          </m.Group>
        </m.Content>
      </bar.Menu>
    </Menubar>
  </template>
}
