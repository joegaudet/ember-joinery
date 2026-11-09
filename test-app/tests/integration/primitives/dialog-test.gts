import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled, triggerEvent, waitUntil } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Dialog } from '@ember-joinery/primitives/dialog'
import { AlertDialog } from '@ember-joinery/primitives/alert-dialog'
import {
  AlertDialogHarness,
  DialogHarness,
  press,
  pressEscape,
  pressKey,
  pressOutside,
  tab,
} from '@ember-joinery/test-support'

/** A wheel turned over an element, as a user scrolling would; returns whether it was cancelled. */
function wheel(element: Element, deltaY: number): boolean {
  const event = new WheelEvent('wheel', { deltaY, bubbles: true, cancelable: true })
  element.dispatchEvent(event)
  return event.defaultPrevented
}

module('Integration | primitives | dialog', function (hooks) {
  setupRenderingTest(hooks)

  test('closed, it renders its trigger and no box of its own', async function (assert) {
    await render(
      <template>
        <Dialog @name="profile" as |d|>
          <d.Trigger>Edit profile</d.Trigger>
          <d.Overlay />
          <d.Content>
            <d.Title>Edit profile</d.Title>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness('profile')

    assert.strictEqual(getComputedStyle(dialog.element).display, 'contents', 'no box')
    assert
      .dom(dialog.trigger)
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasAttribute('aria-haspopup', 'dialog')
      .hasAttribute('aria-expanded', 'false')
      .hasAttribute('data-state', 'closed')
      .hasAttribute('data-slot', 'dialog-trigger')
      .doesNotHaveAttribute('aria-controls', 'nothing to control while closed')
    assert.false(dialog.isOpen)
    assert.strictEqual(dialog.content, null)
    assert.strictEqual(dialog.overlay, null)
    await a11yAudit()
  })

  test('the trigger opens it: in the top layer, named, described, and focused', async function (assert) {
    await render(
      <template>
        <Dialog @name="profile" as |d|>
          <d.Trigger>Edit profile</d.Trigger>
          <d.Overlay />
          <d.Content>
            <d.Title>Edit profile</d.Title>
            <d.Description>Make changes to your profile here.</d.Description>
            <a href="#help">Help</a>
            <input aria-label="Name" value="Pedro Duarte" />
            <d.Close>Done</d.Close>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness('profile')
    await dialog.open()

    assert.true(dialog.isOpen)
    assert.dom(dialog.trigger).hasAttribute('aria-expanded', 'true')
    assert.dom(dialog.trigger).hasAttribute('aria-controls', dialog.content!.id)
    assert.dom(dialog.content).hasAttribute('role', 'dialog').hasAttribute('data-state', 'open')
    assert.dom(dialog.content).hasAttribute('data-slot', 'dialog-content')
    assert.strictEqual(dialog.role, 'dialog')
    assert.true(dialog.isModal)
    assert.strictEqual(dialog.label, 'Edit profile', 'named by its title')
    assert.strictEqual(dialog.descriptionText, 'Make changes to your profile here.')
    assert.dom(dialog.title).hasTagName('h2').hasAttribute('data-slot', 'dialog-title')
    assert.dom(dialog.description).hasTagName('p')
    assert.true(dialog.isInTopLayer, 'the content is in the top layer')
    assert.dom(dialog.overlay).hasAttribute('data-state', 'open')
    assert.true(dialog.overlay!.matches(':popover-open'), 'so is the overlay')
    assert.strictEqual(
      dialog.overlay!.compareDocumentPosition(dialog.content!) & Node.DOCUMENT_POSITION_FOLLOWING,
      Node.DOCUMENT_POSITION_FOLLOWING,
      'the overlay comes first, so the content shows above it',
    )
    assert
      .dom(dialog.content!.querySelector('input'))
      .isFocused('focus moves to the first focusable element that is not a link')
    assert.true(dialog.hasFocus)
    await a11yAudit()
  })

  test('Escape closes it, and focus goes back to the trigger', async function (assert) {
    await render(
      <template>
        <Dialog as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay />
          <d.Content>
            <d.Title>Title</d.Title>
            <button type="button">Inside</button>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()
    assert.true(dialog.hasFocus)

    await dialog.pressEscape()
    assert.false(dialog.isOpen)
    assert.strictEqual(dialog.content, null, 'the content is gone')
    assert.strictEqual(dialog.overlay, null)
    assert.dom(dialog.trigger).isFocused('focus is back on the trigger')
    await a11yAudit()
  })

  test('a press on the overlay closes it; a press inside, or a right click, does not', async function (assert) {
    await render(
      <template>
        <Dialog as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay />
          <d.Content>
            <d.Title>Title</d.Title>
            <p data-test-inside>Inside</p>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()

    await press(dialog.content!.querySelector('[data-test-inside]')!)
    assert.true(dialog.isOpen, 'a press inside keeps it')

    await triggerEvent(dialog.overlay!, 'pointerdown', { button: 2, pointerType: 'mouse' })
    assert.true(dialog.isOpen, 'a right click opens a menu, and keeps it')

    await dialog.pressOutside()
    assert.false(dialog.isOpen, 'a press on the overlay closes it')
    assert.dom(dialog.trigger).isFocused()
    await a11yAudit()
  })

  test('modal: Tab and Shift+Tab stay inside, going round', async function (assert) {
    await render(
      <template>
        <button type="button" data-test-before>Before</button>
        <Dialog as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay />
          <d.Content>
            <d.Title>Title</d.Title>
            <button type="button" data-test-first>First</button>
            <button type="button" data-test-last>Last</button>
          </d.Content>
        </Dialog>
        <button type="button">After</button>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()
    const first = dialog.content!.querySelector('[data-test-first]')!
    const last = dialog.content!.querySelector('[data-test-last]')!
    assert.dom(first).isFocused()

    await tab()
    assert.dom(last).isFocused()
    await tab()
    assert.dom(first).isFocused('Tab from the last goes round to the first')
    await tab({ shift: true })
    assert.dom(last).isFocused('Shift+Tab from the first goes round to the last')

    // Focus can't leave another way (a script): the page behind is inert.
    ;(document.querySelector('[data-test-before]') as HTMLButtonElement).focus()
    await settled()
    assert.true(dialog.hasFocus, 'focus is kept inside')
    await a11yAudit()
  })

  test('modal: the rest of the page is inert until it closes; live regions stay', async function (assert) {
    await render(
      <template>
        <button type="button" data-test-outside>Outside</button>
        <div aria-live="polite" data-test-live>Saved</div>
        <Dialog as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay />
          <d.Content>
            <d.Title>Title</d.Title>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    const outside = document.querySelector('[data-test-outside]')!
    await dialog.open()

    assert.dom(outside).hasAttribute('inert', '', 'the page behind is inert')
    assert.dom(dialog.trigger).hasAttribute('inert')
    assert.dom('[data-test-live]').doesNotHaveAttribute('inert', 'a live region is still heard')
    assert.dom(dialog.content).doesNotHaveAttribute('inert')
    assert.dom(dialog.overlay).doesNotHaveAttribute('inert')
    assert.dom(dialog.content).hasAttribute('aria-modal', 'true')
    await a11yAudit()

    await dialog.close()
    assert.dom(outside).doesNotHaveAttribute('inert', 'all back')
    assert.dom(outside).doesNotHaveAttribute('data-inert-ed')
    assert.dom(dialog.trigger).doesNotHaveAttribute('inert')
    await a11yAudit()
  })

  test('modal: the page does not scroll behind it, but its content does', async function (assert) {
    await render(
      <template>
        <p data-test-page>Page</p>
        <Dialog as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay />
          <d.Content>
            <d.Title>Title</d.Title>
            <div data-test-scroller style="height: 50px; overflow-y: auto" tabindex="0">
              <div style="height: 500px">Long</div>
            </div>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    const body = document.body
    await dialog.open()

    assert.dom(body).hasAttribute('data-scroll-locked', '1')
    assert.strictEqual(getComputedStyle(body).overflow, 'hidden', 'no scrollbar')
    assert.true(wheel(document.querySelector('[data-test-page]')!, 100), 'the page does not scroll')
    assert.true(wheel(dialog.overlay!, 100), 'nor does the overlay')
    const scroller = dialog.content!.querySelector('[data-test-scroller]')!
    assert.false(wheel(scroller, 100), 'the content scrolls')
    assert.true(wheel(scroller, -100), 'but not past its top, onto the page')
    await a11yAudit()

    await dialog.close()
    assert.dom(body).doesNotHaveAttribute('data-scroll-locked')
    assert.notStrictEqual(getComputedStyle(body).overflow, 'hidden', 'the page scrolls again')
    assert.false(wheel(document.querySelector('[data-test-page]')!, 100))
    await a11yAudit()
  })

  test('uncontrolled, it can start open with @defaultOpen', async function (assert) {
    await render(
      <template>
        <Dialog @defaultOpen={{true}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content><d.Title>Title</d.Title></d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    assert.true(dialog.isOpen)
    assert.true(dialog.isInTopLayer)
    await dialog.pressEscape()
    assert.false(dialog.isOpen)
    await a11yAudit()
  })

  test('controlled: @open decides, and @onOpenChange hears what it asks for', async function (assert) {
    class State {
      @tracked open = false
      changes: boolean[] = []
      change = (open: boolean) => this.changes.push(open)
      set = (open: boolean) => {
        this.changes.push(open)
        this.open = open
      }
    }
    const state = new State()
    await render(
      <template>
        <Dialog @name="ignored" @open={{false}} @onOpenChange={{state.change}} as |d|>
          <d.Trigger>Ignored</d.Trigger>
          <d.Content><d.Title>Title</d.Title></d.Content>
        </Dialog>
        <Dialog @name="followed" @open={{state.open}} @onOpenChange={{state.set}} as |d|>
          <d.Trigger>Followed</d.Trigger>
          <d.Content><d.Title>Title</d.Title></d.Content>
        </Dialog>
      </template>,
    )
    const ignored = new DialogHarness('ignored')
    await click(ignored.trigger)
    assert.deepEqual(state.changes, [true], 'it asked to open')
    assert.false(ignored.isOpen, 'but stays as its caller says')

    const followed = new DialogHarness('followed')
    await followed.open()
    assert.true(followed.isOpen)
    await followed.pressEscape()
    assert.false(state.open)
    assert.false(followed.isOpen)

    state.open = true
    await settled()
    assert.true(followed.isOpen, 'the caller can open it')
    assert.true(followed.hasFocus)
    state.open = false
    await settled()
    assert.strictEqual(followed.content, null, 'and close it')
    assert.deepEqual(state.changes, [true, true, false])
    await a11yAudit()
  })

  test('it yields its state, open() and setOpen()', async function (assert) {
    await render(
      <template>
        <Dialog @name="settings" as |d|>
          <span data-test-state>{{if d.isOpen "open" "closed"}}</span>
          <button type="button" data-test-open {{on "click" d.open}}>Open it</button>
          <d.Content>
            <d.Title>Settings</d.Title>
            <button type="button" data-test-close {{on "click" (fn d.setOpen false)}}>Done</button>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness('settings')
    assert.dom('[data-test-state]').hasText('closed')
    await click('[data-test-open]')
    assert.true(dialog.isOpen, 'open() opened it, with no trigger')
    assert.dom('[data-test-state]').hasText('open')
    await click(dialog.content!.querySelector('[data-test-close]')!)
    assert.false(dialog.isOpen)
    assert.dom('[data-test-open]').isFocused('focus goes back where it was')
    await a11yAudit()
  })

  test('your own elements: @as, and the trigger and close modifiers', async function (assert) {
    await render(
      <template>
        <Dialog as |d|>
          <button {{d.trigger}} class="mine">Mine</button>
          <d.Content @as="section">
            <d.Title @as="h3">Title</d.Title>
            <d.Description @as="div">Description</d.Description>
            <d.Close @as="a" href="#closed">Close link</d.Close>
            <button {{d.close}} data-test-own-close>Own close</button>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    assert
      .dom(dialog.trigger)
      .hasClass('mine')
      .hasAttribute('type', 'button', 'a button of your own gets type="button", as in Radix')
    await dialog.open()
    assert.dom(dialog.content).hasTagName('section')
    assert.dom(dialog.title).hasTagName('h3')
    assert.dom(dialog.description).hasTagName('div')
    assert.strictEqual(dialog.label, 'Title')
    const own = dialog.content!.querySelector('[data-test-own-close]')!
    assert.dom(own).hasAttribute('type', 'button').hasAttribute('data-slot', 'dialog-close')
    await click(own)
    assert.false(dialog.isOpen, 'the close modifier closed it')

    await dialog.open()
    await click(dialog.content!.querySelector('a')!)
    assert.false(dialog.isOpen, 'so did the Close part as a link')
    await a11yAudit()
  })

  test('non-modal: no overlay, no trap, the page stays usable, and a press outside closes it', async function (assert) {
    await render(
      <template>
        <button type="button" data-test-outside>Outside</button>
        <Dialog @modal={{false}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay />
          <d.Content>
            <d.Title>Title</d.Title>
            <button type="button">Inside</button>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    const outside = document.querySelector('[data-test-outside]')!
    await dialog.open()

    assert.false(dialog.isModal)
    assert.dom(dialog.content).doesNotHaveAttribute('aria-modal')
    assert.strictEqual(dialog.overlay, null, 'a non-modal dialog has no overlay')
    assert.true(dialog.isInTopLayer)
    assert.dom(outside).doesNotHaveAttribute('inert')
    assert.dom(document.body).doesNotHaveAttribute('data-scroll-locked')
    assert.true(dialog.hasFocus, 'focus still moves in')
    await a11yAudit()

    await press(dialog.trigger)
    assert.false(dialog.isOpen, 'a press on the trigger toggles it closed')
    assert.dom(dialog.trigger).isFocused()

    await dialog.open()
    await press(outside)
    assert.false(dialog.isOpen, 'a press outside closes it')
    assert.dom(outside).isFocused('focus stays where the user put it')
    await a11yAudit()
  })

  test('non-modal: focus moving outside closes it', async function (assert) {
    await render(
      <template>
        <Dialog @modal={{false}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content>
            <d.Title>Title</d.Title>
            <button type="button" data-test-last>Last</button>
          </d.Content>
        </Dialog>
        <button type="button" data-test-after>After</button>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()
    await pressKey('Escape')
    assert.false(dialog.isOpen, 'Escape closes a non-modal one too')

    await dialog.open()
    ;(document.querySelector('[data-test-after]') as HTMLButtonElement).focus()
    await settled()
    assert.false(dialog.isOpen, 'focus went outside')
    await a11yAudit()
  })

  test('the content can keep itself open', async function (assert) {
    const keep = (event: Event) => event.preventDefault()
    await render(
      <template>
        <Dialog as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay />
          <d.Content @onEscapeKeyDown={{keep}} @onPointerDownOutside={{keep}}>
            <d.Title>Title</d.Title>
            <d.Close>Close</d.Close>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()
    await dialog.pressEscape()
    assert.true(dialog.isOpen, 'Escape was cancelled')
    await dialog.pressOutside()
    assert.true(dialog.isOpen, 'the press outside was cancelled')
    await click(dialog.content!.querySelector('button')!)
    assert.false(dialog.isOpen, 'its Close still closes it')
    await a11yAudit()
  })

  test('focus can go elsewhere when it opens and closes', async function (assert) {
    let focusedOnOpen = false
    const intoName = (event: Event) => {
      event.preventDefault()
      ;(document.querySelector('[data-test-name]') as HTMLInputElement).focus()
      focusedOnOpen = true
    }
    const toAfter = (event: Event) => {
      event.preventDefault()
      ;(document.querySelector('[data-test-after]') as HTMLButtonElement).focus()
    }
    await render(
      <template>
        <Dialog as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content @onOpenAutoFocus={{intoName}} @onCloseAutoFocus={{toAfter}}>
            <d.Title>Title</d.Title>
            <button type="button">First</button>
            <input aria-label="Name" data-test-name />
          </d.Content>
        </Dialog>
        <button type="button" data-test-after>After</button>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()
    assert.true(focusedOnOpen)
    assert.dom('[data-test-name]').isFocused()
    await dialog.pressEscape()
    assert.dom('[data-test-after]').isFocused()
    await a11yAudit()
  })

  test('it waits for its exit animation before it goes', async function (assert) {
    await render(
      <template>
        <style>
          @keyframes fx-dialog-out {
            to {
              opacity: 0;
            }
          }
          .fx-animated[data-state="closed"] {
            animation: fx-dialog-out 150ms;
          }
        </style>
        <Dialog as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay class="fx-animated" />
          <d.Content class="fx-animated">
            <d.Title>Title</d.Title>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()
    const content = dialog.content!

    void pressEscape(content)
    await waitUntil(() => content.getAttribute('data-state') === 'closed')
    assert.false(dialog.isOpen, 'closed at once')
    assert.true(content.isConnected, 'but still there while it animates out')
    assert.true(dialog.isInTopLayer, 'and still above the page')

    await settled()
    assert.false(content.isConnected, 'gone once the animation ended')
    assert.dom(dialog.trigger).isFocused()
    await a11yAudit()
  })

  test('nested dialogs: Escape closes the top one only, and focus steps back', async function (assert) {
    await render(
      <template>
        <Dialog @name="outer" as |outer|>
          <outer.Trigger>Settings</outer.Trigger>
          <outer.Overlay />
          <outer.Content>
            <outer.Title>Settings</outer.Title>
            <Dialog @name="inner" as |inner|>
              <inner.Trigger>Advanced</inner.Trigger>
              <inner.Overlay />
              <inner.Content>
                <inner.Title>Advanced</inner.Title>
                <button type="button">Reset</button>
              </inner.Content>
            </Dialog>
          </outer.Content>
        </Dialog>
      </template>,
    )
    const outer = new DialogHarness('outer')
    const inner = new DialogHarness({ name: 'inner', within: outer })
    await outer.open()
    await inner.open()
    assert.true(inner.hasFocus)
    assert.dom(inner.trigger).hasAttribute('inert', '', 'the outer dialog is inert behind it')
    await a11yAudit()

    await pressEscape()
    assert.false(inner.isOpen, 'the inner one closed')
    assert.true(outer.isOpen, 'the outer one stayed')
    assert.dom(inner.trigger).isFocused()
    assert.dom(inner.trigger).doesNotHaveAttribute('inert')

    await pressEscape()
    assert.false(outer.isOpen)
    assert.dom(outer.trigger).isFocused()
    assert.dom(document.body).doesNotHaveAttribute('data-scroll-locked')
    await a11yAudit()
  })

  test('a <form method="dialog"> closes it, and @onClose hears the returnValue', async function (assert) {
    const closes: string[] = []
    const onClose = (value: string) => closes.push(value)
    await render(
      <template>
        <Dialog @onClose={{onClose}} as |d|>
          <d.Trigger>Choose</d.Trigger>
          <d.Content>
            <d.Title>Pick a plan</d.Title>
            <form method="dialog">
              <button type="submit" value="free">Free</button>
              <button type="submit" value="pro">Pro</button>
            </form>
          </d.Content>
          <output data-test-value>{{d.returnValue}}</output>
        </Dialog>
      </template>,
    )
    const dialog = new DialogHarness()
    await dialog.open()
    await click(dialog.content!.querySelector('[value="pro"]')!)
    assert.false(dialog.isOpen, 'submitting the form closed it')
    assert.deepEqual(closes, ['pro'])
    assert.dom('[data-test-value]').hasText('pro')

    await dialog.open()
    assert.dom('[data-test-value]').hasText('', 'it starts empty each time it opens')
    await dialog.pressEscape()
    assert.deepEqual(closes, ['pro', ''], 'Escape closes with no value')
    await a11yAudit()
  })

  test('the harness: one pointed at another component says so', async function (assert) {
    await render(
      <template>
        <AlertDialog @name="delete" as |a|>
          <a.Trigger>Delete</a.Trigger>
        </AlertDialog>
      </template>,
    )
    assert.throws(
      () => new DialogHarness('delete').element,
      /the component named "delete" is a "alert-dialog"; this harness drives "dialog"/,
    )
    assert.true(new AlertDialogHarness('delete').exists)
    assert.false(new DialogHarness('missing').exists)
    await a11yAudit()
  })
})

module('Integration | primitives | alert-dialog', function (hooks) {
  setupRenderingTest(hooks)

  test('modal, with the alertdialog role, and focus on Cancel', async function (assert) {
    await render(
      <template>
        <AlertDialog @name="delete" as |a|>
          <a.Trigger>Delete account</a.Trigger>
          <a.Overlay />
          <a.Content>
            <a.Title>Are you absolutely sure?</a.Title>
            <a.Description>This action cannot be undone.</a.Description>
            <a.Action>Continue</a.Action>
            <a.Cancel>Cancel</a.Cancel>
          </a.Content>
        </AlertDialog>
      </template>,
    )
    const alert = new AlertDialogHarness('delete')
    assert.dom(alert.trigger).hasAttribute('data-slot', 'alert-dialog-trigger')
    await alert.open()

    assert.strictEqual(alert.role, 'alertdialog')
    assert.true(alert.isModal)
    assert.strictEqual(alert.label, 'Are you absolutely sure?')
    assert.strictEqual(alert.descriptionText, 'This action cannot be undone.')
    assert.dom(alert.content).hasAttribute('data-slot', 'alert-dialog-content')
    assert.dom(alert.overlay).hasAttribute('data-slot', 'alert-dialog-overlay')
    assert.dom(alert.cancelButton).isFocused('Cancel, the safe choice, has focus')
    assert.dom(alert.cancelButton).hasAttribute('data-slot', 'alert-dialog-cancel')
    assert.dom(alert.actionButton).hasAttribute('data-slot', 'alert-dialog-action')
    assert.dom(alert.actionButton).hasAttribute('type', 'button')
    await a11yAudit()
  })

  test('a press outside does not close it; Escape, Cancel and Action do', async function (assert) {
    let deleted = 0
    const remove = () => deleted++
    await render(
      <template>
        <AlertDialog as |a|>
          <a.Trigger>Delete</a.Trigger>
          <a.Overlay />
          <a.Content>
            <a.Title>Delete?</a.Title>
            <a.Description>It cannot be undone.</a.Description>
            <a.Cancel>Cancel</a.Cancel>
            <button {{a.action}} {{on "click" remove}}>Delete</button>
          </a.Content>
        </AlertDialog>
      </template>,
    )
    const alert = new AlertDialogHarness()
    await alert.open()

    await alert.pressOutside()
    assert.true(alert.isOpen, 'a press on the overlay keeps it')
    await pressOutside()
    assert.true(alert.isOpen, 'and anywhere outside')

    await alert.pressEscape()
    assert.false(alert.isOpen, 'Escape closes it')
    assert.dom(alert.trigger).isFocused()

    await alert.open()
    await alert.cancel()
    assert.false(alert.isOpen, 'Cancel closes it')
    assert.strictEqual(deleted, 0)

    await alert.open()
    await alert.confirm()
    assert.false(alert.isOpen, 'the action closes it')
    assert.strictEqual(deleted, 1, "and the action's own listener ran")
    await a11yAudit()
  })

  test('the harness closes it with Cancel', async function (assert) {
    await render(
      <template>
        <AlertDialog as |a|>
          <a.Trigger>Delete</a.Trigger>
          <a.Content>
            <a.Title>Delete?</a.Title>
            <a.Description>It cannot be undone.</a.Description>
            <a.Cancel>Cancel</a.Cancel>
          </a.Content>
        </AlertDialog>
      </template>,
    )
    const alert = new AlertDialogHarness()
    await alert.open()
    await alert.close()
    assert.false(alert.isOpen)
    await a11yAudit()
  })
})
