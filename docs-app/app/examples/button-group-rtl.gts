import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import {
  Archive,
  ArrowLeft,
  CalendarPlus,
  Clock,
  ListFilter,
  MailCheck,
  MoreHorizontal,
  Tag,
  Trash2,
} from 'lucide'
import { Button, ButtonGroup, DropdownMenu, Icon } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  archive: 'أرشفة',
  report: 'تقرير',
  snooze: 'تأجيل',
  markAsRead: 'وضع علامة كمقروء',
  addToCalendar: 'إضافة إلى التقويم',
  addToList: 'إضافة إلى القائمة',
  labelAs: 'تصنيف كـ...',
  personal: 'شخصي',
  work: 'عمل',
  other: 'آخر',
  trash: 'سلة المهملات',
}

export default class ButtonGroupRtl extends Component {
  @tracked label = 'personal'

  setLabel = (label: string) => (this.label = label)

  <template>
    {{!
      Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), as upstream's
      `<div dir>` shows it; its menus take `data-lang`, as upstream's do.
    }}
    <ButtonGroup>
      <ButtonGroup class="hidden sm:flex">
        <Button @variant="outline" @size="icon" aria-label="Go Back">
          <Icon @icon={{ArrowLeft}} class="rtl:rotate-180" />
        </Button>
      </ButtonGroup>
      <ButtonGroup>
        <Button @variant="outline">{{t.archive}}</Button>
        <Button @variant="outline">{{t.report}}</Button>
      </ButtonGroup>
      <ButtonGroup>
        <Button @variant="outline">{{t.snooze}}</Button>
        <DropdownMenu as |m|>
          <Button @variant="outline" @size="icon" aria-label="More Options" {{m.trigger}}>
            <Icon @icon={{MoreHorizontal}} />
          </Button>
          <m.Content @align="end" data-lang="ar" class="w-40">
            <m.Group>
              <m.Item>
                <Icon @icon={{MailCheck}} />
                {{t.markAsRead}}
              </m.Item>
              <m.Item>
                <Icon @icon={{Archive}} />
                {{t.archive}}
              </m.Item>
            </m.Group>
            <m.Separator />
            <m.Group>
              <m.Item>
                <Icon @icon={{Clock}} />
                {{t.snooze}}
              </m.Item>
              <m.Item>
                <Icon @icon={{CalendarPlus}} />
                {{t.addToCalendar}}
              </m.Item>
              <m.Item>
                <Icon @icon={{ListFilter}} />
                {{t.addToList}}
              </m.Item>
              <m.Sub as |s|>
                <s.Trigger>
                  <Icon @icon={{Tag}} />
                  {{t.labelAs}}
                </s.Trigger>
                <m.Portal>
                  <s.Content data-lang="ar">
                    <m.RadioGroup @value={{this.label}} @onValueChange={{this.setLabel}} as |g|>
                      <g.Item @value="personal">{{t.personal}}</g.Item>
                      <g.Item @value="work">{{t.work}}</g.Item>
                      <g.Item @value="other">{{t.other}}</g.Item>
                    </m.RadioGroup>
                  </s.Content>
                </m.Portal>
              </m.Sub>
            </m.Group>
            <m.Separator />
            <m.Group>
              <m.Item @variant="destructive">
                <Icon @icon={{Trash2}} />
                {{t.trash}}
              </m.Item>
            </m.Group>
          </m.Content>
        </DropdownMenu>
      </ButtonGroup>
    </ButtonGroup>
  </template>
}
