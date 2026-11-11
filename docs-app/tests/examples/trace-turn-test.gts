import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TraceCollapsibleHarness, TraceHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import TraceTurn from 'docs-app/examples/trace-turn'

module('Example | trace-turn', function (hooks) {
  setupRenderingTest(hooks)

  test('a whole turn: a summary, its rows, and text between two traces', async function (assert) {
    await render(<template><TraceTurn /></template>)
    const [turn, thought, commands, failed] = TraceCollapsibleHarness.findAll()
    assert.true(turn!.isOpen)
    assert.true(turn!.line.isError)
    assert.strictEqual(turn!.line.title, 'Worked for 2m 4s, 1 command failed')
    assert.false(thought!.isOpen)
    assert.strictEqual(thought!.line.description, '12s')
    assert.true(commands!.isOpen)
    assert.true(commands!.line.isError)
    await failed!.open()
    const output = failed!.find(CodeBlockHarness)
    assert.strictEqual(output.variant, 'destructive')
    assert.strictEqual(output.code, 'command not found: pnpm')
    const traces = turn!.findAll(TraceHarness)
    assert.strictEqual(traces.length, 3, 'two at the top level of the turn, one nested')
    assert
      .dom(turn!.content.querySelector('p'))
      .hasText('Node is installed and pnpm is not. Reading the docs config.')
    await a11yAudit()
  })
})
