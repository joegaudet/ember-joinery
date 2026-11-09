import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'
import CodeBlockAnsi from 'docs-app/examples/code-block-ansi'

module('Example | code-block-ansi', function (hooks) {
  setupRenderingTest(hooks)
  const clipboard = setupClipboard(hooks)

  test('terminal output in its own colours, copied without the escape codes', async function (assert) {
    await render(<template><CodeBlockAnsi /></template>)
    const block = new CodeBlockHarness()
    assert.true(block.isHighlighted)
    assert.strictEqual(
      block.lines[1]!.text,
      '✓ src/format.test.ts (4 tests)',
      'no escape codes show',
    )
    const [pass] = block.tokens(1)
    const [fail] = block.tokens(3)
    assert.strictEqual(pass!.text, '✓')
    assert.strictEqual(fail!.text, '✗')
    assert.notStrictEqual(pass!.color, fail!.color, 'green and red')
    assert.true(block.isWrapped)

    await block.copy()
    assert.strictEqual(clipboard.text, block.code, 'the plain text')
    assert.notOk(clipboard.text?.includes('\x1b'))
    await a11yAudit()
  })
})
