import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { NativeSelectHarness } from '@ember-joinery/test-support'
import NativeSelectDemo from 'docs-app/examples/native-select-demo'

module('Example | native-select-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a status select that starts on its prompt', async function (assert) {
    await render(<template><NativeSelectDemo /></template>)
    const status = new NativeSelectHarness()

    assert.strictEqual(status.label, 'Status')
    assert.deepEqual(status.options, ['', 'todo', 'in-progress', 'done', 'cancelled'])
    assert.strictEqual(status.selectedText, 'Select status')
    await status.select('in-progress')
    assert.strictEqual(status.value, 'in-progress')
    assert.strictEqual(status.selectedText, 'In Progress')
    await a11yAudit()
  })
})
