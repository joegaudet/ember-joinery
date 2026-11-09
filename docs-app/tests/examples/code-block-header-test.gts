import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { IconHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'
import CodeBlockHeader from 'docs-app/examples/code-block-header'

module('Example | code-block-header', function (hooks) {
  setupRenderingTest(hooks)
  const clipboard = setupClipboard(hooks)

  test('a titled header whose copy button copies the command, not the output', async function (assert) {
    await render(<template><CodeBlockHeader /></template>)
    const block = new CodeBlockHarness()

    assert.strictEqual(block.title, 'Terminal')
    assert.true(block.find(IconHarness).isDecorative, "the title's icon is decoration")
    assert.strictEqual(block.lines[0]!.text, '$ pnpm add ai @ai-sdk/react zod')
    assert.false(block.hasFloatingActions)

    await block.copy()
    assert.strictEqual(clipboard.text, 'pnpm add ai @ai-sdk/react zod')
    assert.true(block.isCopied)
    assert.strictEqual(block.status, 'Copied')
    await a11yAudit()
  })
})
