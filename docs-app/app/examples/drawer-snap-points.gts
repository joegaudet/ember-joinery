import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { Button, Drawer, type SnapPoint } from '@ember-joinery/ember'

/** vaul's snap points: 148px, 355px, then all the way up (1 is the whole screen). */
const SNAP_POINTS: SnapPoint[] = ['148px', '355px', 1]

export default class DrawerSnapPoints extends Component {
  @tracked snap: SnapPoint | null = SNAP_POINTS[0]!

  setSnap = (snap: SnapPoint | null): void => {
    this.snap = snap
  }

  <template>
    <Drawer
      @snapPoints={{SNAP_POINTS}}
      @activeSnapPoint={{this.snap}}
      @onActiveSnapPointChange={{this.setSnap}}
      @fadeFromIndex={{1}}
      as |d|
    >
      <Button @variant="outline" {{d.trigger}}>Open Drawer</Button>
      <d.Content class="h-full max-h-[97%]">
        <d.Header>
          <d.Title>Snap points</d.Title>
          <d.Description>
            Drag it up or down, and it rests at the nearest of three heights. The overlay comes in
            from the second.
          </d.Description>
        </d.Header>
        <div class="flex flex-wrap justify-center gap-2 px-4">
          <Button @variant="outline" @size="sm" {{on "click" (fn this.setSnap "148px")}}>
            148px
          </Button>
          <Button @variant="outline" @size="sm" {{on "click" (fn this.setSnap "355px")}}>
            355px
          </Button>
          <Button @variant="outline" @size="sm" {{on "click" (fn this.setSnap 1)}}>
            Full
          </Button>
        </div>
        <p class="px-4 pt-4 text-center text-sm text-muted-foreground" aria-live="polite">
          Resting at
          {{this.snap}}
        </p>
      </d.Content>
    </Drawer>
  </template>
}
