import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockHighlightedLines from 'docs-app/examples/code-block-highlighted-lines'

module('Example | code-block-highlighted-lines', function (hooks) {
  setupRenderingTest(hooks)

  test('two lines called out', async function (assert) {
    await render(<template><CodeBlockHighlightedLines /></template>)
    const block = new CodeBlockHarness()
    assert.deepEqual(block.highlightedLines, [2, 3])
    assert.deepEqual(
      block.highlightedLines.map(index => block.lines[index]!.text.trim()),
      ['reactCompiler: true,', 'viewTransition: true,'],
    )
    const [, , look] = block.parts('line')
    const [plain] = block.parts('line')
    assert.notStrictEqual(
      getComputedStyle(look!).backgroundColor,
      getComputedStyle(plain!).backgroundColor,
      'tinted',
    )
    await a11yAudit()
  })
})
