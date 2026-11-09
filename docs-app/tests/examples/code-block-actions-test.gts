import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'
import CodeBlockActions from 'docs-app/examples/code-block-actions'

module('Example | code-block-actions', function (hooks) {
  setupRenderingTest(hooks)
  const clipboard = setupClipboard(hooks)

  test('a wrap toggle that starts on, a download button and a copy button', async function (assert) {
    await render(<template><CodeBlockActions /></template>)
    const block = new CodeBlockHarness()
    const [wrap, download, copy] = ButtonHarness.findAll()

    assert.deepEqual(
      [wrap!.label, download!.label, copy!.label],
      ['Wrap lines', 'Download', 'Copy'],
    )
    assert.true(wrap!.isPressed)
    assert.true(block.isWrapped, 'the lint output wraps to start with')
    await wrap!.click()
    assert.false(wrap!.isPressed)
    assert.false(block.isWrapped, 'and scrolls once the toggle is off')

    await block.copy()
    assert.strictEqual(clipboard.text, block.code)
    assert.ok(block.code.startsWith('$ pnpm lint'))
    await a11yAudit()
  })
})
