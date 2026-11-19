// The components `ember-joinery add` copies into an app (`pnpm copy` puts every one in
// app/joinery, as `ember-joinery add --all` does in any app): they build and typecheck as app
// code, Joinery's CSS styles them, and the harnesses drive them as they drive the package's.
import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DialogHarness, child } from '@ember-joinery/test-support'
import Button from 'test-app/joinery/components/button.gts'
import Dialog from 'test-app/joinery/components/dialog.gts'
import * as packaged from '@ember-joinery/ember'

class EditProfile extends DialogHarness {
  static override named = 'edit-profile'
  @child(ButtonHarness, 'save') declare save: ButtonHarness
}

module('Integration | copied components', function (hooks) {
  setupRenderingTest(hooks)

  test('a copied Dialog is the app’s own module, not the package’s', function (assert) {
    assert.notStrictEqual(Dialog, packaged.Dialog)
    assert.notStrictEqual(Button, packaged.Button)
  })

  test('the Dialog harness drives a copied Dialog, and Joinery’s CSS styles it', async function (assert) {
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
              <Button @name="save" {{d.close}}>Save changes</Button>
            </d.Footer>
          </d.Content>
        </Dialog>
      </template>,
    )
    const dialog = new EditProfile()
    assert.false(dialog.isOpen)
    await dialog.open()
    assert.true(dialog.isOpen)
    assert.true(dialog.isModal)
    assert.strictEqual(dialog.label, 'Edit profile')
    assert.dom(dialog.content).hasClass('jn-dialog-content')
    assert.notStrictEqual(
      getComputedStyle(dialog.content!).position,
      'static',
      'joinery.css positions the copied content',
    )
    await a11yAudit()
    await dialog.save.click()
    assert.false(dialog.isOpen)
  })
})
