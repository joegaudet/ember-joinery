import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, InputHarness, SheetHarness, child } from '@ember-joinery/test-support'
import SheetDemo from 'docs-app/examples/sheet-demo'

/** The profile sheet: a page object, with its fields and buttons declared. */
class EditProfileSheet extends SheetHarness {
  @child(InputHarness, { index: 0 }) declare fullName: InputHarness
  @child(InputHarness, { index: 1 }) declare username: InputHarness

  /** A button of the example's own, by its text (the corner's close button left out). */
  button(text: string): ButtonHarness {
    return this.findAll(ButtonHarness).find(
      button => button.text === text && button.element !== this.closeButton,
    )!
  }
}

module('Example | sheet-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a profile form in a sheet from the right', async function (assert) {
    await render(<template><SheetDemo /></template>)
    const sheet = new EditProfileSheet()
    assert.dom(sheet.trigger).hasText('Open')
    await sheet.open()
    assert.strictEqual(sheet.side, 'right')
    assert.strictEqual(sheet.label, 'Edit profile')
    assert.strictEqual(
      sheet.descriptionText,
      "Make changes to your profile here. Click save when you're done.",
    )

    assert.strictEqual(sheet.fullName.label, 'Name', 'its label names it')
    assert.strictEqual(sheet.fullName.value, 'Pedro Duarte')
    assert.strictEqual(sheet.username.label, 'Username')
    assert.strictEqual(sheet.username.value, '@peduarte')
    assert.true(sheet.fullName.isFocused, 'focus goes to the first field')
    await a11yAudit()

    await sheet.fullName.fillIn('Ada Lovelace')
    assert.strictEqual(sheet.fullName.value, 'Ada Lovelace')
    const save = sheet.button('Save changes')
    assert.dom(save.element).hasAttribute('type', 'submit')
    await save.click()
    assert.true(sheet.isOpen, 'Save changes is not a close')

    const close = sheet.button('Close')
    assert.strictEqual(close.variant, 'outline')
    await close.click()
    assert.false(sheet.isOpen, "the footer's Close closes it")
    assert.dom(sheet.trigger).isFocused()
    await a11yAudit()
  })
})
