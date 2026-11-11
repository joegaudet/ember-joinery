import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MessageHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'
import CodeBlockChat from 'docs-app/examples/code-block-chat'

module('Example | code-block-chat', function (hooks) {
  setupRenderingTest(hooks)
  const clipboard = setupClipboard(hooks)

  test('a question, and an answer with a code block between its paragraphs', async function (assert) {
    await render(<template><CodeBlockChat /></template>)
    const [question, answer] = MessageHarness.findAll()

    assert.strictEqual(question!.align, 'end')
    assert.strictEqual(question!.bubbles[0]!.text, 'How do I stream a response?')

    assert.strictEqual(answer!.align, 'start')
    assert.strictEqual(answer!.bubbles.length, 0, 'the answer is plain text, no bubble')
    assert.strictEqual(getComputedStyle(answer!.content).rowGap, '12px', 'gap-3')
    const block = answer!.find(CodeBlockHarness)
    assert.strictEqual(block.title, 'app/api/chat/route.ts')
    assert.strictEqual(block.lines[0]!.text, 'import { streamText } from "ai"')
    assert.dom(answer!.content).includesText('Create a route handler that returns the stream:')
    assert.dom(answer!.content).includesText('The client reads it with useChat.')

    await block.copy()
    assert.ok(clipboard.text?.startsWith('import { streamText } from "ai"'), 'it copies the code')
    await a11yAudit()
  })
})
