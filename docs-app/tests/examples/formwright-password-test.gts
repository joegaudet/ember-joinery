import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ProgressHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import { InputFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightPassword from 'docs-app/examples/formwright-password'

class PasswordForm extends FormHarness {
  static override formName = 'create-password'
  @field(InputFieldHarness) declare password: InputFieldHarness
}

module('Example | formwright-password', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('the meter fills as the password meets each requirement', async function (assert) {
    await render(
      <template>
        <FormwrightPassword />
        <Toaster />
      </template>,
    )
    const form = new PasswordForm()
    const meter = new ProgressHarness()
    assert.dom(form.password.control).hasAttribute('type', 'password')
    assert.strictEqual(meter.value, 0)

    await form.password.fillIn('short')
    assert.strictEqual(meter.value, 20, 'one of five: lower case')
    await form.submit()
    assert.deepEqual(form.password.errors, [
      'Password must be at least 8 characters',
      'Password must contain at least one uppercase letter',
      'Password must contain at least one number',
      'Password must contain at least one special character',
    ])
    await a11yAudit()

    await form.password.fillIn('Str0ng!pass')
    assert.strictEqual(meter.value, 100)
    assert.false(form.password.isInvalid)
    await form.submit()
    assert.deepEqual(JSON.parse(new ToasterHarness().toast().description!), {
      password: 'Str0ng!pass',
    })
    await a11yAudit()
  })
})
