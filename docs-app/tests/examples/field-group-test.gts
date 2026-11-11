import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  CheckboxHarness,
  FieldGroupHarness,
  FieldSetHarness,
  LabelHarness,
} from '@ember-joinery/test-support'
import FieldGroupExample from 'docs-app/examples/field-group'

module('Example | field-group', function (hooks) {
  setupRenderingTest(hooks)

  test('two sets of notification checkboxes, divided by a separator', async function (assert) {
    await render(<template><FieldGroupExample /></template>)
    const group = new FieldGroupHarness({ index: 0 })
    const [responses, tasks] = FieldSetHarness.findAll()

    assert.deepEqual(group.separators, [''])
    assert.strictEqual(responses!.find(LabelHarness).text, 'Responses')
    assert.true(responses!.description.startsWith('Get notified when ChatGPT responds'))
    const push = responses!.find(CheckboxHarness)
    assert.true(push.isChecked)
    assert.true(push.isDisabled)
    assert.strictEqual(push.label, 'Push notifications')

    assert.strictEqual(tasks!.find(LabelHarness).text, 'Tasks')
    assert.strictEqual(
      tasks!.description,
      "Get notified when tasks you've created have updates. Manage tasks",
    )
    const link = tasks!.part('description').querySelector('a')!
    assert.strictEqual(getComputedStyle(link).textDecorationLine, 'underline', '[&>a]:underline')
    assert.deepEqual(
      tasks!.fields.map(field => field.label),
      ['Push notifications', 'Email notifications'],
    )
    const email = tasks!.findAll(CheckboxHarness)[1]!
    await email.check()
    assert.true(email.isChecked)
    assert.strictEqual(
      getComputedStyle(tasks!.find(FieldGroupHarness).element).rowGap,
      '12px',
      'a checkbox group sits closer together',
    )
    await a11yAudit()
  })
})
