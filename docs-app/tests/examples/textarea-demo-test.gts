import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TextareaHarness } from '@ember-joinery/test-support'
import TextareaDemo from 'docs-app/examples/textarea-demo'

module('Example | textarea-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a textarea that takes several lines', async function (assert) {
    await render(<template><TextareaDemo /></template>)
    const textarea = new TextareaHarness()

    assert.strictEqual(textarea.placeholder, 'Type your message here.')
    assert.strictEqual(textarea.label, 'Type your message here.')
    await textarea.fillIn('Line one\nLine two')
    assert.strictEqual(textarea.value, 'Line one\nLine two')
    await a11yAudit()
  })
})
