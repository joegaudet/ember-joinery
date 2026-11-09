import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockBasic from 'docs-app/examples/code-block-basic'

module('Example | code-block-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('build output as one plain string', async function (assert) {
    await render(<template><CodeBlockBasic /></template>)
    const block = new CodeBlockHarness()

    assert.strictEqual(block.lines[0]!.text, '$ pnpm build')
    assert.strictEqual(block.lines.at(-1)!.text, '└ ƒ /api/chat             141 B         102 kB')
    assert.strictEqual(block.lines.length, 10)
    assert.false(block.isNumbered)
    assert.false(block.isHighlighted)
    assert.strictEqual(block.title, null, 'no header')
    await a11yAudit()
  })
})
