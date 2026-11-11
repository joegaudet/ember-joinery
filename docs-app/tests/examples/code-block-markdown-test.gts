import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, MessageHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockMarkdown from 'docs-app/examples/code-block-markdown'
import { chatTiming } from 'docs-app/examples/chat/scripted-chat'

module('Example | code-block-markdown', function (hooks) {
  setupRenderingTest(hooks)
  hooks.beforeEach(() => void (chatTiming.scale = 0))
  hooks.afterEach(() => void (chatTiming.scale = 1))

  test("a reply's Markdown, its fenced code a Code Block", async function (assert) {
    await render(<template><CodeBlockMarkdown /></template>)
    const [question, answer] = MessageHarness.findAll()
    assert.strictEqual(question!.align, 'end')
    assert.strictEqual(question!.text, 'How do I debounce a search input in React?')

    const paragraphs = Array.from(answer!.content.querySelectorAll('p'))
    assert.strictEqual(paragraphs.length, 2)
    assert.strictEqual(
      paragraphs[0]!.textContent,
      'Wrap the value in a useDebounce hook. It returns the latest value once it stops changing for delay milliseconds.',
    )
    assert.deepEqual(
      Array.from(paragraphs[0]!.querySelectorAll('code')).map(code => code.textContent),
      ['useDebounce', 'delay'],
      'inline code',
    )
    assert.strictEqual(
      paragraphs[1]!.textContent,
      'Pass the debounced value to your fetch instead of the raw input.',
    )

    const block = answer!.find(CodeBlockHarness)
    assert.strictEqual(block.title, 'tsx', 'the fence names its language')
    assert.strictEqual(block.lines.length, 10)
    assert.true(block.code.startsWith('export function useDebounce<T>(value: T, delay = 300) {'))
    assert.true(block.canCopy, 'the closing fence has arrived')
    await a11yAudit()

    const replayButton = () => ButtonHarness.findAll().find(button => button.label === 'Replay')
    await replayButton()!.click()
    const [, again] = MessageHarness.findAll()
    assert.strictEqual(again!.find(CodeBlockHarness).lines.length, 10, 'streamed in again')
    assert.ok(replayButton(), 'Replay shows once the reply is done')
    await a11yAudit()
  })
})
