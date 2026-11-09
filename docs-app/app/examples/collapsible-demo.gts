import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { ChevronsUpDown } from 'lucide'
import { Button, Collapsible, Icon } from '@ember-joinery/ember'

export default class CollapsibleDemo extends Component {
  @tracked isOpen = false

  setIsOpen = (open: boolean) => (this.isOpen = open)

  <template>
    <Collapsible
      @open={{this.isOpen}}
      @onOpenChange={{this.setIsOpen}}
      class="flex w-[350px] flex-col gap-2"
      as |c|
    >
      <div class="flex items-center justify-between gap-4 px-4">
        <h4 class="text-sm font-semibold">Order #4189</h4>
        <Button @variant="ghost" @size="icon" class="size-8" {{c.trigger}}>
          <Icon @icon={{ChevronsUpDown}} />
          <span class="sr-only">Toggle details</span>
        </Button>
      </div>
      <div class="flex items-center justify-between rounded-md border px-4 py-2 text-sm">
        <span class="text-muted-foreground">Status</span>
        <span class="font-medium">Shipped</span>
      </div>
      <c.Content class="flex flex-col gap-2">
        <div class="rounded-md border px-4 py-2 text-sm">
          <p class="font-medium">Shipping address</p>
          <p class="text-muted-foreground">100 Market St, San Francisco</p>
        </div>
        <div class="rounded-md border px-4 py-2 text-sm">
          <p class="font-medium">Items</p>
          <p class="text-muted-foreground">2x Studio Headphones</p>
        </div>
      </c.Content>
    </Collapsible>
  </template>
}
