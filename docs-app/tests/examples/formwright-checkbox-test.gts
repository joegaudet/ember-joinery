import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import {
  CheckboxFieldHarness,
  CheckboxGroupFieldHarness,
} from '@ember-joinery/formwright/test-support'
import FormwrightCheckbox from 'docs-app/examples/formwright-checkbox'

class NotificationsForm extends FormHarness {
  static override formName = 'notifications'
  @field(CheckboxFieldHarness) declare responses: CheckboxFieldHarness
  @field(CheckboxGroupFieldHarness) declare tasks: CheckboxGroupFieldHarness
}

module('Example | formwright-checkbox', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('Responses is checked and fixed; Tasks needs one', async function (assert) {
    await render(
      <template>
        <FormwrightCheckbox />
        <Toaster />
      </template>,
    )
    const notifications = new NotificationsForm()
    assert.true(notifications.responses.value)
    assert.true(notifications.responses.isDisabled)
    assert.strictEqual(notifications.tasks.label, 'Tasks')
    assert.deepEqual(notifications.tasks.options, ['push', 'email'])

    await notifications.submit()
    assert.deepEqual(notifications.tasks.errors, ['Please select at least one notification type.'])
    await a11yAudit()

    await notifications.tasks.toggle('email')
    assert.deepEqual(notifications.tasks.value, ['email'])
    await notifications.submit()
    assert.deepEqual(JSON.parse(new ToasterHarness().toast().description!), {
      responses: true,
      tasks: ['email'],
    })
    await a11yAudit()
  })
})
