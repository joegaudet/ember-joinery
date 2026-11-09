import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { ChevronsUpDown } from 'lucide'
import { Button, Collapsible, Icon } from '@ember-joinery/ember'

export default class CollapsibleRtl extends Component {
  @tracked isOpen = false

  setIsOpen = (open: boolean) => (this.isOpen = open)

  <template>
    {{!
      Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
      Arabic. Upstream leaves the trigger's hidden name in English ("Toggle details"); Joinery's
      is in Arabic too, as a right-to-left page would name it. It is read aloud, not drawn, so
      the screenshot is the same.
    }}
    <Collapsible
      @open={{this.isOpen}}
      @onOpenChange={{this.setIsOpen}}
      class="flex w-[350px] flex-col gap-2"
      as |c|
    >
      <div class="flex items-center justify-between gap-4 px-4">
        <h4 class="text-sm font-semibold">الطلب #4189</h4>
        <Button @variant="ghost" @size="icon" class="size-8" {{c.trigger}}>
          <Icon @icon={{ChevronsUpDown}} />
          <span class="sr-only">تبديل التفاصيل</span>
        </Button>
      </div>
      <div class="flex items-center justify-between rounded-md border px-4 py-2 text-sm">
        <span class="text-muted-foreground">الحالة</span>
        <span class="font-medium">تم الشحن</span>
      </div>
      <c.Content class="flex flex-col gap-2">
        <div class="rounded-md border px-4 py-2 text-sm">
          <p class="font-medium">عنوان الشحن</p>
          <p class="text-muted-foreground">100 Market St, San Francisco</p>
        </div>
        <div class="rounded-md border px-4 py-2 text-sm">
          <p class="font-medium">العناصر</p>
          <p class="text-muted-foreground">2x سماعات الاستوديو</p>
        </div>
      </c.Content>
    </Collapsible>
  </template>
}
