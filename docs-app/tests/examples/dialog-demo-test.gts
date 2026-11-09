import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  DialogHarness,
  FieldGroupHarness,
  InputHarness,
  child,
} from '@ember-joinery/test-support'
import DialogDemo from 'docs-app/examples/dialog-demo'

/** The profile dialog: a page object, with its fields and buttons declared. */
class EditProfileDialog extends DialogHarness {
  @child(InputHarness, { index: 0 }) declare fullName: InputHarness
  @child(InputHarness, { index: 1 }) declare username: InputHarness

  /** A button of the example's own, by its text. */
  button(text: string): ButtonHarness {
    return this.findAll(ButtonHarness).find(button => button.text === text)!
  }
}

module('Example | dialog-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a profile form in a dialog: Save submits it, Cancel closes it', async function (assert) {
    const submitted: Array<Array<[string, unknown]>> = []
    const record = (event: SubmitEvent) => {
      event.preventDefault()
      submitted.push([...new FormData(event.target as HTMLFormElement).entries()])
    }
    document.addEventListener('submit', record)
    try {
      await render(<template><DialogDemo /></template>)
      const dialog = new EditProfileDialog()
      assert.dom(dialog.trigger).hasText('Open Dialog')
      await dialog.open()
      assert.strictEqual(dialog.label, 'Edit profile')
      assert.strictEqual(
        dialog.descriptionText,
        "Make changes to your profile here. Click save when you're done.",
      )
      assert.deepEqual(
        dialog.find(FieldGroupHarness).fields.map(field => field.label),
        ['Name', 'Username'],
      )
      assert.strictEqual(dialog.fullName.label, 'Name')
      assert.strictEqual(dialog.fullName.value, 'Pedro Duarte')
      assert.strictEqual(dialog.username.value, '@peduarte')
      await a11yAudit()

      await dialog.username.fillIn('@ada')
      await dialog.button('Save changes').click()
      assert.deepEqual(
        submitted,
        [
          [
            ['name', 'Pedro Duarte'],
            ['username', '@ada'],
          ],
        ],
        'the dialog is inside the form, so Save submits its fields',
      )

      await dialog.button('Cancel').click()
      assert.false(dialog.isOpen)
      assert.dom(dialog.trigger).isFocused()
      await a11yAudit()
    } finally {
      document.removeEventListener('submit', record)
    }
  })
})
