import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Form, lookupControl, registerControl, type ErrorMap } from '@ember-formwright/ember'
import Input from '@ember-formwright/ember/controls/input'
import Select from '@ember-formwright/ember/controls/select'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Button, Card, Dialog, asButton } from '@ember-joinery/ember'
import { ButtonHarness, CardHarness, DialogHarness, child } from '@ember-joinery/test-support'
import {
  InputControl,
  SelectControl,
  joineryControls,
  registerJoineryControls,
  setupJoineryForms,
} from '@ember-joinery/formwright'
import { InputFieldHarness, findForm, form } from '@ember-joinery/formwright/test-support'

class Profile {
  @tracked name = ''
  @tracked email = ''
}

const requireName = (model: Profile): ErrorMap => (model.name ? {} : { name: ['Enter a name.'] })

class ProfileForm extends FormHarness {
  @field(InputFieldHarness) declare name: InputFieldHarness
  @field(InputFieldHarness) declare email: InputFieldHarness
}

class EditProfile extends DialogHarness {
  static override named = 'edit-profile'
  @child(ButtonHarness, 'save') declare save: ButtonHarness
  @form(ProfileForm) declare profile: ProfileForm
}

class Account extends CardHarness {
  @form(ProfileForm, 'contact') declare contact: ProfileForm
}

module('Integration | formwright | harnesses', function (hooks) {
  setupRenderingTest(hooks)

  hooks.before(function () {
    setupJoineryForms()
  })

  test("@form finds a Formwright form inside a Joinery component, through the dialog's top layer", async function (assert) {
    const model = new Profile()
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
            <Form
              @model={{model}}
              @name="profile"
              @validator={{requireName}}
              @onSubmit={{save}}
              as |f|
            >
              <f.Field @for="name" @label="Name" />
              <f.Field @for="email" @control="email" @label="Email" />
              <d.Footer>
                <f.Submit {{asButton name="save"}}>Save changes</f.Submit>
              </d.Footer>
            </Form>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new EditProfile()
    assert.strictEqual(dialog.profile, dialog.profile, 'the form harness is made once')
    await dialog.open()
    await dialog.save.click()
    assert.deepEqual(dialog.profile.name.errors, ['Enter a name.'])
    assert.strictEqual(dialog.profile.status, 'invalid')
    await dialog.profile.name.fillIn('Ada')
    await dialog.profile.email.fillIn('ada@example.com')
    await dialog.save.click()
    assert.strictEqual(saved, 1)
    assert.strictEqual(model.name, 'Ada')
    assert.strictEqual(dialog.profile.name.value, 'Ada')
    assert
      .dom(dialog.save.element)
      .hasClass('jn-button', "Formwright's submit, as Joinery's Button")
    await a11yAudit()
  })

  test('@form and findForm() find a form by name, by static formName, or the first', async function (assert) {
    const model = new Profile()
    const other = new Profile()
    other.name = 'Grace'
    await render(
      <template>
        <Card>
          <Form @model={{other}} @name="other" as |f|>
            <f.Field @for="name" @label="Other name" />
          </Form>
          <Form @model={{model}} @name="contact" as |f|>
            <f.Field @for="name" @label="Contact name" />
          </Form>
        </Card>
      </template>,
    )
    const card = new Account()
    assert.strictEqual(card.contact.name.label, 'Contact name', 'by the name @form gives')
    assert.strictEqual(findForm(card, ProfileForm).name.label, 'Other name', 'else the first')
    class Named extends ProfileForm {
      static override formName = 'contact'
    }
    assert.strictEqual(findForm(card, Named).name.label, 'Contact name', 'or its static formName')
    await a11yAudit()
  })

  test('registerJoineryControls() can leave out or pick controls', async function (assert) {
    try {
      registerControl('input', Input)
      registerControl('select', Select)
      registerJoineryControls({ except: ['select'] })
      assert.strictEqual(lookupControl('input'), InputControl)
      assert.strictEqual(lookupControl('select'), Select, "Formwright's own select stays")
      registerJoineryControls({ only: ['select'] })
      assert.strictEqual(lookupControl('select'), SelectControl)
      assert.strictEqual(joineryControls['native-select'], lookupControl('native-select'))
    } finally {
      setupJoineryForms()
    }
    await render(
      <template>
        <p>Registered.</p>
      </template>,
    )
    await a11yAudit()
  })
})
