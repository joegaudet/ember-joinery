import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, FieldSetHarness, RadioGroupHarness } from '@ember-joinery/test-support'
import RadioGroupInvalid from 'docs-app/examples/radio-group-invalid'

module('Example | radio-group-invalid', function (hooks) {
  setupRenderingTest(hooks)

  test('every choice invalid, in the destructive colour', async function (assert) {
    await render(<template><RadioGroupInvalid /></template>)
    const set = new FieldSetHarness()
    const group = new RadioGroupHarness()

    assert.strictEqual(set.legend, 'Notification Preferences')
    assert.deepEqual(
      group.options.map(value => group.isItemInvalid(value)),
      [true, true, true],
    )
    assert.true(FieldHarness.findAll().every(field => field.isInvalid))
    assert.strictEqual(group.labelOf('both'), 'Both Email & SMS')
    await group.choose('sms')
    assert.strictEqual(group.value, 'sms')
    await a11yAudit()
  })
})
