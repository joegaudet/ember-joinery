import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { ButtonHarness, DialogHarness, child } from '@ember-joinery/test-support'
import { InputFieldHarness, form } from '@ember-joinery/formwright/test-support'
import FormwrightDialog from 'docs-app/examples/formwright-dialog'

class ProfileForm extends FormHarness {
  @field(InputFieldHarness) declare name: InputFieldHarness
  @field(InputFieldHarness) declare username: InputFieldHarness
}

/** The dialog, its save button, and its Formwright form. */
class EditProfile extends DialogHarness {
  static override named = 'edit-profile'
  @child(ButtonHarness, 'save') declare save: ButtonHarness
  @form(ProfileForm, 'profile') declare profile: ProfileForm
}

module('Example | formwright-dialog', function (hooks) {
  setupRenderingTest(hooks)

  test("the dialog's form is checked on save, and a valid save closes it", async function (assert) {
    await render(<template><FormwrightDialog /></template>)
    const dialog = new EditProfile()
    await dialog.open()
    assert.strictEqual(dialog.profile.name.value, 'Pedro Duarte')

    await dialog.profile.name.fillIn('')
    await dialog.save.click()
    assert.deepEqual(dialog.profile.name.errors, ['Enter your name.'])
    assert.true(dialog.isOpen, 'an invalid save keeps it open')
    await a11yAudit()

    await dialog.profile.name.fillIn('Ada Lovelace')
    await dialog.save.click()
    assert.false(dialog.isOpen, 'a valid save closes it')
    await a11yAudit()
  })
})
