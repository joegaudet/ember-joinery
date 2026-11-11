import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import { InputFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightInput from 'docs-app/examples/formwright-input'

class ProfileForm extends FormHarness {
  static override formName = 'profile'
  @field(InputFieldHarness) declare username: InputFieldHarness
}

module('Example | formwright-input', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('the username is checked against every rule, and saved once it passes', async function (assert) {
    await render(
      <template>
        <FormwrightInput />
        <Toaster />
      </template>,
    )
    const profile = new ProfileForm()
    assert.strictEqual(profile.username.label, 'Username')
    assert.dom(profile.username.control).hasAttribute('autocomplete', 'username')

    await profile.username.fillIn('a b')
    await profile.submit()
    assert.deepEqual(profile.username.errors, [
      'Username can only contain letters, numbers, and underscores.',
    ])
    assert.true(profile.username.isInvalid)
    await a11yAudit()

    await profile.username.fillIn('shadcn')
    assert.false(profile.username.isInvalid)
    await profile.submit()
    assert.deepEqual(JSON.parse(new ToasterHarness().toast().description!), { username: 'shadcn' })
    await a11yAudit()
  })
})
