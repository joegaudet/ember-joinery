import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { DatePickerFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightDatePicker from 'docs-app/examples/formwright-date-picker'

class ProfileForm extends FormHarness {
  static override formName = 'profile'
  @field(DatePickerFieldHarness) declare dob: DatePickerFieldHarness
}

module('Example | formwright-date-picker', function (hooks) {
  setupRenderingTest(hooks)

  test('the button opens a calendar, and the day picked fills the field', async function (assert) {
    await render(<template><FormwrightDatePicker /></template>)
    const profile = new ProfileForm()
    assert.strictEqual(profile.dob.text, 'Select date')
    assert.true(profile.dob.isEmpty)
    await profile.dob.pick('1990-06-15')
    assert.strictEqual(profile.dob.text, 'June 15, 1990')
    assert.false(profile.dob.isEmpty)
    assert.true(profile.dob.isDirty)
    await a11yAudit()
  })
})
