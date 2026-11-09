import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockStreaming from 'docs-app/examples/code-block-streaming'

module('Example | code-block-streaming', function (hooks) {
  setupRenderingTest(hooks)

  test('Replay streams five blocks in again, highlighting as they arrive', async function (assert) {
    await render(<template><CodeBlockStreaming /></template>)
    // Replay comes after the blocks, so its position moves as they stream in: find it each time.
    const replay = () => ButtonHarness.findAll().at(-1)!
    assert.strictEqual(CodeBlockHarness.findAll().length, 5, 'it starts complete')
    assert.strictEqual(replay().label, 'Replay')
    assert.false(replay().isDisabled)

    await replay().click()
    assert.true(replay().isDisabled, 'Replay waits for the stream')
    assert.ok(CodeBlockHarness.findAll().length < 5, 'the blocks arrive one by one')
    const first = new CodeBlockHarness()
    await waitUntil(() => first.exists && first.lines[0]!.text.length > 0, { timeout: 5000 })
    assert.false(first.canCopy, "the first block can't be copied until it is whole")

    await waitUntil(() => !replay().isDisabled, { timeout: 20000 })
    const [debounce, command, search, route, env] = CodeBlockHarness.findAll()
    assert.strictEqual(debounce!.title, 'hooks/use-debounce.ts')
    assert.true(debounce!.canCopy)
    assert.strictEqual(command!.title, null, 'a command, with no header')
    assert.deepEqual(search!.removedLines, [2])
    assert.deepEqual(search!.addedLines, [3, 4])
    assert.deepEqual(route!.highlightedLines, [5, 6, 7, 8])
    assert.strictEqual(env!.code, 'AI_GATEWAY_API_KEY=your-api-key')
    assert.true(route!.isHighlighted)
    await a11yAudit()
  })
})
