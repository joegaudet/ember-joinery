import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  DialogHarness,
  DrawerHarness,
  InputHarness,
  child,
} from '@ember-joinery/test-support'
import DrawerDialog from 'docs-app/examples/drawer-dialog'

/** The profile form, in whichever of the two it is. */
class ProfileDrawer extends DrawerHarness {
  @child(InputHarness, { index: 0 }) declare email: InputHarness
  @child(InputHarness, { index: 1 }) declare username: InputHarness
}

class ProfileDialog extends DialogHarness {
  @child(InputHarness, { index: 0 }) declare email: InputHarness
  @child(InputHarness, { index: 1 }) declare username: InputHarness
}

/** A stand-in for `matchMedia`, whose answer the test changes as a resized window would. */
class FakeMedia {
  matches: boolean
  #listeners = new Set<() => void>()
  constructor(matches: boolean) {
    this.matches = matches
  }
  addEventListener(_: string, listener: () => void) {
    this.#listeners.add(listener)
  }
  removeEventListener(_: string, listener: () => void) {
    this.#listeners.delete(listener)
  }
  change(matches: boolean) {
    this.matches = matches
    for (const listener of this.#listeners) listener()
  }
}

module('Example | drawer-dialog', function (hooks) {
  setupRenderingTest(hooks)

  let original: typeof window.matchMedia
  let media: FakeMedia
  hooks.beforeEach(function () {
    original = window.matchMedia
    media = new FakeMedia(false)
    window.matchMedia = (() => media) as unknown as typeof window.matchMedia
  })
  hooks.afterEach(function () {
    window.matchMedia = original
  })

  test('on a phone, the profile form is in a drawer', async function (assert) {
    await render(<template><DrawerDialog /></template>)
    const drawer = new ProfileDrawer()
    assert.dom(drawer.trigger).hasText('Edit Profile')
    await drawer.open()
    assert.strictEqual(drawer.direction, 'bottom')
    assert.strictEqual(drawer.label, 'Edit profile')
    assert.strictEqual(
      drawer.descriptionText,
      "Make changes to your profile here. Click save when you're done.",
    )
    assert.strictEqual(drawer.email.value, 'shadcn@example.com')
    assert.strictEqual(drawer.email.label, 'Email')
    assert.strictEqual(drawer.username.value, '@shadcn')
    assert.strictEqual(drawer.username.label, 'Username')
    assert.dom(drawer.content).isFocused("focus is on the drawer, so a phone's keyboard stays down")
    await a11yAudit()

    await drawer
      .findAll(ButtonHarness)
      .find(button => button.text === 'Cancel')!
      .click()
    assert.false(drawer.isOpen, 'Cancel closes it')
    await a11yAudit()
  })

  test('on a wider screen, the same form is in a dialog, and it follows the width', async function (assert) {
    media.matches = true
    await render(<template><DrawerDialog /></template>)
    const dialog = new ProfileDialog()
    assert.false(new DrawerHarness().exists, 'no drawer')
    await dialog.open()
    assert.strictEqual(dialog.label, 'Edit profile')
    assert.true(dialog.email.isFocused, 'a dialog focuses its first field')
    assert.strictEqual(dialog.username.value, '@shadcn')
    await a11yAudit()
    await dialog.close()
    assert.false(dialog.isOpen)

    media.change(false)
    await settled()
    assert.false(dialog.exists, 'narrowed, the dialog gives way')
    assert.true(new DrawerHarness().exists, 'to a drawer')
    await a11yAudit()
  })
})
