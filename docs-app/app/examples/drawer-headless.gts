import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Drawer } from '@ember-joinery/primitives/drawer'

/**
 * The headless Drawer, styled with nothing but utility classes: it brings the behaviour (the
 * Dialog's, with vaul's drag, its handle and its slides) and you bring the look. `@onDrag` says
 * how far toward closed it is.
 */
export default class DrawerHeadless extends Component {
  @tracked dragged = 0

  onDrag = (_: PointerEvent, percentage: number): void => {
    this.dragged = Math.round(percentage * 100)
  }

  onRelease = (): void => {
    this.dragged = 0
  }

  <template>
    <Drawer @onDrag={{this.onDrag}} @onRelease={{this.onRelease}} as |d|>
      <d.Trigger class="rounded-md border px-3 py-1.5 text-sm">Move goal</d.Trigger>
      <d.Overlay class="fixed inset-0 bg-black/40" />
      <d.Content
        class="fixed inset-x-0 bottom-0 flex flex-col gap-3 rounded-t-2xl bg-background p-5 pt-3 text-foreground shadow-lg"
      >
        <d.Handle class="mx-auto h-1.5 w-12 rounded-full bg-muted" />
        <d.Title class="text-lg font-semibold">Move goal</d.Title>
        <d.Description class="text-sm text-muted-foreground">
          Drag me down to close me:
          {{this.dragged}}% of the way.
        </d.Description>
        <d.Close class="self-end rounded-md border px-3 py-1.5 text-sm">Done</d.Close>
      </d.Content>
    </Drawer>
  </template>
}
