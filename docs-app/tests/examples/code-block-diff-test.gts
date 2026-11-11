import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'
import CodeBlockDiff from 'docs-app/examples/code-block-diff'

module('Example | code-block-diff', function (hooks) {
  setupRenderingTest(hooks)
  const clipboard = setupClipboard(hooks)

  test('a patch: one line removed and three added, each with its marker', async function (assert) {
    await render(<template><CodeBlockDiff /></template>)
    const block = new CodeBlockHarness()
    assert.strictEqual(block.title, 'components/greeting.tsx')
    assert.deepEqual(block.removedLines, [1])
    assert.deepEqual(block.addedLines, [2, 3, 4])
    assert.strictEqual(
      block.lines[1]!.text,
      '  return <p>Hello, {name}</p>',
      "the marker isn't part of the code",
    )
    const lines = block.parts('line')
    assert.strictEqual(getComputedStyle(lines[1]!, '::after').content, '"−"')
    assert.strictEqual(getComputedStyle(lines[2]!, '::after').content, '"+"')

    await block.copy()
    assert.ok(clipboard.text?.includes('-  return <p>Hello, {name}</p>'), 'copy copies the patch')
    await a11yAudit()
  })
})
