import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockStartLine from 'docs-app/examples/code-block-start-line'

module('Example | code-block-start-line', function (hooks) {
  setupRenderingTest(hooks)

  test('a snippet from the middle of a file, numbered from line 995', async function (assert) {
    await render(<template><CodeBlockStartLine /></template>)
    const block = new CodeBlockHarness()
    assert.strictEqual(block.title, 'app/dashboard/page.tsx')
    assert.strictEqual(block.startLine, 995)
    assert.strictEqual(block.lines[0]!.number, 995)
    assert.strictEqual(block.lines.at(-1)!.number, 1005)
    assert.true(block.isHighlighted)
    // The gutter grows to fit four digits, so the code still lines up.
    const first = block.parts('line')[0]!
    const gutter = Number.parseFloat(getComputedStyle(first, '::before').width)
    assert.ok(gutter > 24, `the gutter is wider than its min-w-6 (${gutter}px)`)
    await a11yAudit()
  })
})
