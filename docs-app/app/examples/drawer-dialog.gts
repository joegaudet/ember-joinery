import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { isDestroying } from '@ember/destroyable'
import type { TOC } from '@ember/component/template-only'
import { modifier } from 'ember-modifier'
import { Button, Dialog, Drawer, Input, Label } from '@ember-joinery/ember'

const DESKTOP = '(min-width: 768px)'

const ProfileForm: TOC<{ Element: HTMLFormElement }> = <template>
  <form class="grid items-start gap-6" ...attributes>
    <div class="grid gap-3">
      <Label for="email">Email</Label>
      <Input type="email" id="email" @defaultValue="shadcn@example.com" />
    </div>
    <div class="grid gap-3">
      <Label for="username">Username</Label>
      <Input id="username" @defaultValue="@shadcn" />
    </div>
    <Button type="submit">Save changes</Button>
  </form>
</template>

export default class DrawerDialogDemo extends Component {
  @tracked open = false
  /** Upstream's `useMediaQuery("(min-width: 768px)")`. */
  @tracked isDesktop = matchMedia(DESKTOP).matches

  setOpen = (open: boolean): void => {
    this.open = open
  }

  /**
   * Keeps `isDesktop` as the query changes. It asks the window the example renders in, which,
   * in the guide's width presets, is an `<iframe>` that wide, not the guide's own.
   */
  mediaQuery = modifier((element: Element, [query]: [string]) => {
    const media = (element.ownerDocument.defaultView ?? window).matchMedia(query)
    const update = () => {
      if (!isDestroying(this) && this.isDesktop !== media.matches) this.isDesktop = media.matches
    }
    media.addEventListener('change', update)
    void Promise.resolve().then(update)
    return () => media.removeEventListener('change', update)
  })

  <template>
    {{#if this.isDesktop}}
      <Dialog @open={{this.open}} @onOpenChange={{this.setOpen}} {{this.mediaQuery DESKTOP}} as |d|>
        <Button @variant="outline" {{d.trigger}}>Edit Profile</Button>
        <d.Content class="sm:max-w-[425px]">
          <d.Header>
            <d.Title>Edit profile</d.Title>
            <d.Description>
              Make changes to your profile here. Click save when you're done.
            </d.Description>
          </d.Header>
          <ProfileForm />
        </d.Content>
      </Dialog>
    {{else}}
      <Drawer @open={{this.open}} @onOpenChange={{this.setOpen}} {{this.mediaQuery DESKTOP}} as |d|>
        <Button @variant="outline" {{d.trigger}}>Edit Profile</Button>
        <d.Content>
          <d.Header class="text-left">
            <d.Title>Edit profile</d.Title>
            <d.Description>
              Make changes to your profile here. Click save when you're done.
            </d.Description>
          </d.Header>
          <ProfileForm class="px-4" />
          <d.Footer class="pt-2">
            <Button @variant="outline" {{d.close}}>Cancel</Button>
          </d.Footer>
        </d.Content>
      </Drawer>
    {{/if}}
  </template>
}
