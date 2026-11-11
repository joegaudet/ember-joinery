import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CurrencyHarness, FormHarness, field } from '@ember-formwright/test-support'
import {
  NativeSelectFieldHarness,
  NumberFieldHarness,
} from '@ember-joinery/formwright/test-support'
import FormwrightNativeSelect from 'docs-app/examples/formwright-native-select'

class TaskForm extends FormHarness {
  static override formName = 'task'
  // `status` is the form's own (clean, dirty…), so the field's harness has another name.
  @field(NativeSelectFieldHarness, 'status') declare taskStatus: NativeSelectFieldHarness
  @field(NumberFieldHarness) declare estimate: NumberFieldHarness
  @field(CurrencyHarness) declare budget: CurrencyHarness
}

module('Example | formwright-native-select', function (hooks) {
  setupRenderingTest(hooks)

  test("a native select, a number and a currency, each in Joinery's controls", async function (assert) {
    await render(<template><FormwrightNativeSelect /></template>)
    const task = new TaskForm()
    assert.strictEqual(task.taskStatus.value, 'todo')
    assert.deepEqual(task.taskStatus.options, ['todo', 'in-progress', 'done', 'cancelled'])
    await task.taskStatus.select('done')
    assert.strictEqual(task.taskStatus.value, 'done')

    assert.strictEqual(task.estimate.value, 3)
    await task.estimate.fillIn(5)
    assert.strictEqual(task.estimate.value, 5)

    assert.strictEqual(task.budget.value, '$1,200.00')
    await task.budget.fillIn('2500')
    assert.strictEqual(task.budget.value, '$2,500.00')
    await a11yAudit()
  })
})
