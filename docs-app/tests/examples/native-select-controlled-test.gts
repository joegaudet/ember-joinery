import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, NativeSelectHarness } from '@ember-joinery/test-support'
import NativeSelectControlled from 'docs-app/examples/native-select-controlled'

module('Example | native-select-controlled', function (hooks) {
  setupRenderingTest(hooks)

  test('the parent owns the status: the select and the button both change it', async function (assert) {
    await render(<template><NativeSelectControlled /></template>)
    const status = new NativeSelectHarness('status')
    const markDone = new ButtonHarness('mark-done')

    assert.strictEqual(status.value, 'in-progress', 'it shows @value')
    await status.select('todo')
    assert.strictEqual(status.selectedText, 'Todo', '@onValueChange took the choice')

    await markDone.click()
    assert.strictEqual(status.value, 'done', 'and the parent can set it')
    assert.true(markDone.isDisabled)
    await a11yAudit()
  })
})
