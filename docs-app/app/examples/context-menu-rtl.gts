import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { ArrowLeft, ArrowRight, RotateCw } from 'lucide'
import { ContextMenu, Icon } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  rightClick: 'انقر بزر الماوس الأيمن هنا',
  longPress: 'اضغط مطولاً هنا',
  navigation: 'التنقل',
  back: 'رجوع',
  forward: 'تقدم',
  reload: 'إعادة تحميل',
  moreTools: 'المزيد من الأدوات',
  savePage: 'حفظ الصفحة...',
  createShortcut: 'إنشاء اختصار...',
  nameWindow: 'تسمية النافذة...',
  developerTools: 'أدوات المطور',
  delete: 'حذف',
  showBookmarks: 'إظهار الإشارات المرجعية',
  showFullUrls: 'إظهار عناوين URL الكاملة',
  people: 'الأشخاص',
  pedro: 'Pedro Duarte',
  colm: 'Colm Tuite',
}

export default class ContextMenuRtl extends Component {
  @tracked people = 'pedro'

  setPeople = (people: string) => (this.people = people)

  <template>
    <ContextMenu as |c|>
      <c.Trigger
        class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm"
      >
        <span class="hidden pointer-fine:inline-block">{{t.rightClick}}</span>
        <span class="hidden pointer-coarse:inline-block">
          {{t.longPress}}
        </span>
      </c.Trigger>
      <c.Content class="w-48">
        <c.Group>
          <c.Sub as |navigation|>
            <navigation.Trigger>{{t.navigation}}</navigation.Trigger>
            <navigation.Content class="w-44">
              <c.Group>
                <c.Item>
                  <Icon @icon={{ArrowLeft}} />
                  {{t.back}}
                  <c.Shortcut>⌘[</c.Shortcut>
                </c.Item>
                <c.Item @disabled={{true}}>
                  <Icon @icon={{ArrowRight}} />
                  {{t.forward}}
                  <c.Shortcut>⌘]</c.Shortcut>
                </c.Item>
                <c.Item>
                  <Icon @icon={{RotateCw}} />
                  {{t.reload}}
                  <c.Shortcut>⌘R</c.Shortcut>
                </c.Item>
              </c.Group>
            </navigation.Content>
          </c.Sub>
          <c.Sub as |tools|>
            <tools.Trigger>{{t.moreTools}}</tools.Trigger>
            <tools.Content class="w-44">
              <c.Group>
                <c.Item>{{t.savePage}}</c.Item>
                <c.Item>{{t.createShortcut}}</c.Item>
                <c.Item>{{t.nameWindow}}</c.Item>
              </c.Group>
              <c.Separator />
              <c.Group>
                <c.Item>{{t.developerTools}}</c.Item>
              </c.Group>
              <c.Separator />
              <c.Group>
                <c.Item @variant="destructive">
                  {{t.delete}}
                </c.Item>
              </c.Group>
            </tools.Content>
          </c.Sub>
        </c.Group>
        <c.Separator />
        <c.Group>
          <c.CheckboxItem @checked={{true}}>
            {{t.showBookmarks}}
          </c.CheckboxItem>
          <c.CheckboxItem>{{t.showFullUrls}}</c.CheckboxItem>
        </c.Group>
        <c.Separator />
        <c.Group>
          <c.RadioGroup @value={{this.people}} @onValueChange={{this.setPeople}} as |g|>
            <c.Label>{{t.people}}</c.Label>
            <g.Item @value="pedro">{{t.pedro}}</g.Item>
            <g.Item @value="colm">{{t.colm}}</g.Item>
          </c.RadioGroup>
        </c.Group>
      </c.Content>
    </ContextMenu>
  </template>
}
