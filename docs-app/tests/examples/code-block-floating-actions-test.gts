import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'
import CodeBlockFloatingActions from 'docs-app/examples/code-block-floating-actions'

module('Example | code-block-floating-actions', function (hooks) {
  setupRenderingTest(hooks)
  const clipboard = setupClipboard(hooks)

  test('without a header, the copy button floats and shows on focus', async function (assert) {
    await render(<template><CodeBlockFloatingActions /></template>)
    const block = new CodeBlockHarness()
    assert.true(block.hasFloatingActions)
    assert.strictEqual(block.header, null)

    await block.focusContent()
    await waitUntil(() => getComputedStyle(block.actions!).opacity === '1', { timeout: 1000 })
    assert.strictEqual(getComputedStyle(block.actions!).opacity, '1', 'focus inside shows it')

    await block.copy()
    assert.strictEqual(clipboard.text?.split('\n').length, 7, 'all of the output')
    await a11yAudit()
  })
})
