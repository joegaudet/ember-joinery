import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import { SwitchFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightSwitch from 'docs-app/examples/formwright-switch'

class SecurityForm extends FormHarness {
  static override formName = 'security'
  @field(SwitchFieldHarness) declare twoFactor: SwitchFieldHarness
}

module('Example | formwright-switch', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('multi-factor authentication must be on to save', async function (assert) {
    await render(
      <template>
        <FormwrightSwitch />
        <Toaster />
      </template>,
    )
    const security = new SecurityForm()
    assert.false(security.twoFactor.value)
    await security.submit()
    assert.deepEqual(security.twoFactor.errors, [
      'It is highly recommended to enable two-factor authentication.',
    ])
    await a11yAudit()

    await security.twoFactor.check()
    assert.false(security.twoFactor.isInvalid)
    await security.submit()
    assert.deepEqual(JSON.parse(new ToasterHarness().toast().description!), { twoFactor: true })
    await a11yAudit()
  })
})
