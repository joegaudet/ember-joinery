import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CircleX } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, Dialog } from '@ember-joinery/ember'
import { ButtonHarness, DialogHarness, IconHarness, child, tab } from '@ember-joinery/test-support'

/** Ends the content's entrance animation, so it is measured where it rests. */
function settle(element: Element | null): void {
  for (const animation of element?.getAnimations() ?? []) animation.finish()
}

/** The page object a reader would write for this dialog. */
class EditProfile extends DialogHarness {
  static override named = 'edit-profile'
  @child(ButtonHarness, 'save') declare save: ButtonHarness
}

module('Integration | components | dialog', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's parts, with their classes and data attributes", async function (assert) {
    await render(
      <template>
        <Dialog @name="edit-profile" as |d|>
          <Button @variant="outline" {{d.trigger}}>Edit profile</Button>
          <d.Content>
            <d.Header>
              <d.Title>Edit profile</d.Title>
              <d.Description>Make changes to your profile here.</d.Description>
            </d.Header>
            <d.Footer>
              <Button @variant="outline" @name="cancel" {{d.close}}>Cancel</Button>
              <Button @name="save">Save changes</Button>
            </d.Footer>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new EditProfile()
    assert.dom(dialog.element).hasAttribute('data-test-jn', 'dialog')
    assert
      .dom(dialog.trigger)
      .hasClass('jn-button')
      .hasClass('jn-button-variant-outline')
      .hasAttribute('data-slot', 'dialog-trigger', "the trigger's data-slot, as upstream's asChild")
      .hasAttribute('type', 'button')
    await dialog.open()

    assert
      .dom(dialog.overlay)
      .hasClass('jn-dialog-overlay')
      .hasAttribute('data-slot', 'dialog-overlay')
    assert
      .dom(dialog.content)
      .hasClass('jn-dialog-content')
      .hasAttribute('data-slot', 'dialog-content')
    assert.dom(dialog.content).hasAttribute('data-state', 'open')
    assert.dom('[data-slot="dialog-header"]', dialog.content!).hasClass('jn-dialog-header')
    assert.dom('[data-slot="dialog-footer"]', dialog.content!).hasClass('jn-dialog-footer')
    assert
      .dom(dialog.title)
      .hasTagName('h2')
      .hasClass('jn-dialog-title')
      .hasClass('jn-font-heading')
      .hasAttribute('data-slot', 'dialog-title')
    assert.dom(dialog.description).hasClass('jn-dialog-description')
    assert
      .dom(dialog.closeButton)
      .hasClass('jn-dialog-close')
      .hasClass('jn-button-variant-ghost')
      .hasClass('jn-button-size-icon-sm')
      .hasAttribute('data-slot', 'dialog-close')
      .hasAttribute('type', 'button')
    assert
      .dom(dialog.find(ButtonHarness, 'cancel').element)
      .hasAttribute('data-slot', 'dialog-close')
    assert.strictEqual(dialog.label, 'Edit profile')
    assert.strictEqual(
      dialog.save.label,
      'Save changes',
      'a child harness finds it in the top layer',
    )
    await a11yAudit()
  })

  test("the site's example: a Save that saves and closes, driven by a page object", async function (assert) {
    let saved = 0
    const save = () => saved++
    await render(
      <template>
        <Dialog @name="edit-profile" as |d|>
          <Button @variant="outline" {{d.trigger}}>Edit profile</Button>
          <d.Content>
            <d.Header>
              <d.Title>Edit profile</d.Title>
              <d.Description>Make changes to your profile here.</d.Description>
            </d.Header>
            <d.Footer>
              <Button @variant="outline" {{d.close}}>Cancel</Button>
              <Button @name="save" {{d.close}} {{on "click" save}}>Save changes</Button>
            </d.Footer>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new EditProfile()
    await dialog.open()
    await dialog.save.click()
    assert.false(dialog.isOpen)
    assert.strictEqual(saved, 1)
    assert.dom(dialog.trigger).isFocused()
    await a11yAudit()
  })

  test('its style sheet centres it over the page, without Tailwind', async function (assert) {
    await render(
      <template>
        <Dialog as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content>
            <d.Header>
              <d.Title>Title</d.Title>
              <d.Description>Description</d.Description>
            </d.Header>
            <d.Footer>
              <Button>Save</Button>
            </d.Footer>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()
    const content = dialog.content!
    settle(content)
    const style = getComputedStyle(content)
    const rect = content.getBoundingClientRect()

    assert.strictEqual(style.position, 'fixed')
    assert.strictEqual(style.display, 'grid')
    assert.strictEqual(style.maxWidth, '384px', 'sm:max-w-sm')
    assert.strictEqual(rect.width, 384, 'w-full, up to its maximum')
    assert.strictEqual(style.paddingTop, '16px', 'p-4')
    assert.strictEqual(style.borderTopLeftRadius, '14px', "rounded-xl: the theme's --radius × 1.4")
    assert.notStrictEqual(style.backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-popover')
    assert.strictEqual(style.borderTopWidth, '0px', "none of the browser's popover border")
    assert.ok(
      Math.abs(rect.left + rect.width / 2 - window.innerWidth / 2) <= 1,
      'centred across the page',
    )
    assert.ok(Math.abs(rect.top + rect.height / 2 - window.innerHeight / 2) <= 1, 'and down it')

    const overlay = getComputedStyle(dialog.overlay!)
    assert.strictEqual(overlay.position, 'fixed')
    assert.strictEqual(dialog.overlay!.getBoundingClientRect().width, window.innerWidth, 'inset-0')
    assert.strictEqual(dialog.overlay!.getBoundingClientRect().height, window.innerHeight)
    assert.ok(/^oklab\(0 .*\/ 0\.1\)$/.test(overlay.backgroundColor), 'bg-black/10')

    const close = getComputedStyle(dialog.closeButton!)
    assert.strictEqual(close.position, 'absolute')
    assert.strictEqual(close.top, '8px', 'top-2')
    assert.strictEqual(close.right, '8px', 'end-2')
    assert.strictEqual(close.width, '28px', 'icon-sm')

    const footer = getComputedStyle(content.querySelector('[data-slot="dialog-footer"]')!)
    assert.strictEqual(footer.display, 'flex')
    assert.strictEqual(footer.flexDirection, 'row', 'sm:flex-row')
    assert.strictEqual(footer.justifyContent, 'flex-end', 'sm:justify-end')
    assert.strictEqual(footer.marginLeft, '-16px', 'it reaches the edges: -mx-4')
    assert.strictEqual(footer.borderTopWidth, '1px')
    assert.strictEqual(getComputedStyle(dialog.title!).fontSize, '16px', 'text-base')
    assert.strictEqual(getComputedStyle(dialog.title!).fontWeight, '500')
    assert.strictEqual(getComputedStyle(dialog.description!).fontSize, '14px')
    await a11yAudit()
  })

  test('it animates in and out with the data-state animations', async function (assert) {
    await render(
      <template>
        <Dialog as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content><d.Title>Title</d.Title></d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()
    assert.strictEqual(getComputedStyle(dialog.content!).animationName, 'enter', 'animate-in')
    assert.strictEqual(getComputedStyle(dialog.overlay!).animationName, 'enter')
    await dialog.close()
    assert.strictEqual(dialog.content, null, 'gone once animate-out ended')
    await a11yAudit()
  })

  test('@showCloseButton, the close label and icon, and the footer close button', async function (assert) {
    await render(
      <template>
        <Dialog @name="none" @defaultOpen={{true}} as |d|>
          <d.Content @showCloseButton={{false}}>
            <d.Title>No close button</d.Title>
            <d.Footer @showCloseButton={{true}} />
          </d.Content>
        </Dialog>
      </template>,
    )
    const none = new DialogHarness('none')
    assert.strictEqual(none.closeButton, null, 'no close button in the corner')
    const footerClose = none.find(ButtonHarness)
    assert.strictEqual(footerClose.label, 'Close', "the footer's, upstream's showCloseButton")
    assert.strictEqual(footerClose.variant, 'outline')
    await footerClose.click()
    assert.false(none.isOpen)
    await a11yAudit()
  })

  test('the close button takes a label and an icon', async function (assert) {
    await render(
      <template>
        <Dialog @defaultOpen={{true}} as |d|>
          <d.Content @closeLabel="Fermer" @closeIcon={{CircleX}}>
            <d.Title>Titre</d.Title>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    const close = new ButtonHarness({ within: dialog, index: 0 })
    assert.strictEqual(close.label, 'Fermer', 'its hidden text names it')
    assert.dom(close.element.querySelector('svg')).hasClass('lucide')
    assert.true(close.find(IconHarness).isDecorative)
    assert.strictEqual(
      close.element.querySelector('circle')?.getAttribute('r'),
      '10',
      "lucide's circle-x",
    )
    await dialog.close()
    assert.false(dialog.isOpen)
    await a11yAudit()
  })

  test('keyboard: focus moves in, Tab stays inside, Escape closes, and focus goes back', async function (assert) {
    await render(
      <template>
        <Dialog as |d|>
          <Button @variant="outline" {{d.trigger}}>Open</Button>
          <d.Content>
            <d.Title>Title</d.Title>
            <d.Footer>
              <Button @name="cancel" @variant="outline" {{d.close}}>Cancel</Button>
              <Button @name="save">Save</Button>
            </d.Footer>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()
    const cancel = dialog.find(ButtonHarness, 'cancel')
    const save = dialog.find(ButtonHarness, 'save')
    assert.true(cancel.isFocused, 'focus moves to the first button')

    await tab()
    assert.true(save.isFocused)
    await tab()
    assert.dom(dialog.closeButton).isFocused('the close button comes last')
    await tab()
    assert.true(cancel.isFocused, 'and Tab goes round')

    await dialog.pressEscape()
    assert.false(dialog.isOpen)
    assert.dom(dialog.trigger).isFocused()
    await a11yAudit()
  })

  test('a press on the overlay, the close button, or a close part closes it', async function (assert) {
    await render(
      <template>
        <Dialog as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content>
            <d.Title>Title</d.Title>
            <d.Close>Done</d.Close>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()
    await dialog.pressOutside()
    assert.false(dialog.isOpen, 'the overlay')
    assert.dom(dialog.trigger).isFocused()

    await dialog.open()
    await click(dialog.closeButton!)
    assert.false(dialog.isOpen, 'the close button')

    await dialog.open()
    await click(dialog.content!.querySelector('[data-slot="dialog-close"]:not(.jn-dialog-close)')!)
    assert.false(dialog.isOpen, 'its Close part')
    await a11yAudit()
  })

  test('controlled with @open and @onOpenChange', async function (assert) {
    class State {
      @tracked open = false
      set = (open: boolean) => (this.open = open)
    }
    const state = new State()
    await render(
      <template>
        <Dialog @open={{state.open}} @onOpenChange={{state.set}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content><d.Title>Title</d.Title></d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    state.open = true
    await settled()
    assert.true(dialog.isOpen)
    await dialog.close()
    assert.false(state.open, 'the close button asked, and the caller closed it')
    await a11yAudit()
  })

  test('RTL: the close button moves to the start, and it stays centred', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Dialog @defaultOpen={{true}} as |d|>
            <d.Content>
              <d.Title>تعديل الملف الشخصي</d.Title>
            </d.Content>
          </Dialog>
        </DirectionProvider>
      </template>,
    )
    const dialog = new DialogHarness()
    settle(dialog.content)
    const close = getComputedStyle(dialog.closeButton!)
    assert.strictEqual(close.left, '8px', 'end-2 is on the left, right to left')
    const rect = dialog.content!.getBoundingClientRect()
    assert.ok(
      Math.abs(rect.left + rect.width / 2 - window.innerWidth / 2) <= 1,
      'start-1/2 with rtl:translate-x-1/2 keeps it centred',
    )
    assert.strictEqual(getComputedStyle(dialog.content!).direction, 'rtl')
    await a11yAudit()
  })
})
