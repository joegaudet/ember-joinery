import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockHeight from 'docs-app/examples/code-block-height'

module('Example | code-block-height', function (hooks) {
  setupRenderingTest(hooks)

  test('forty log lines in a capped block that scrolls', async function (assert) {
    await render(<template><CodeBlockHeight /></template>)
    const block = new CodeBlockHarness()
    assert.strictEqual(block.lines.length, 40)
    assert.strictEqual(getComputedStyle(block.content).maxHeight, '192px', 'max-h-48')
    assert.ok(block.content.scrollHeight > block.content.clientHeight, 'it scrolls inside')
    assert.notStrictEqual(
      getComputedStyle(block.content).maskImage,
      'none',
      'scroll-fade-y fades its edges',
    )
    await block.focusContent()
    assert.dom(block.content).isFocused('a keyboard can scroll it')
    await a11yAudit()
  })
})
