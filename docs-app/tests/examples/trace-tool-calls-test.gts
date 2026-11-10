import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, MessageHarness, TraceHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import TraceToolCalls from 'docs-app/examples/trace-tool-calls'
import { chatTiming } from 'docs-app/examples/trace/scripted-chat'

module('Example | trace-tool-calls', function (hooks) {
  setupRenderingTest(hooks)

  hooks.beforeEach(() => {
    chatTiming.scale = 0
  })
  hooks.afterEach(() => {
    chatTiming.scale = 1
  })

  test('tool calls stream in as rows, one failing, then the reply', async function (assert) {
    await render(<template><TraceToolCalls /></template>)
    await new ButtonHarness().click()
    const [, reply] = MessageHarness.findAll()
    const trace = reply!.find(TraceHarness)
    assert.deepEqual(trace.titles, [
      'Ran node --version',
      'Ran npm --version',
      'Failed to run pnpm --version',
    ])
    const [node, , pnpm] = trace.collapsibles
    await node!.open()
    assert.strictEqual(node!.find(CodeBlockHarness).code, 'v24.18.0')
    assert.true(pnpm!.line.isError)
    await pnpm!.open()
    assert.strictEqual(pnpm!.find(CodeBlockHarness).code, 'command not found: pnpm')
    assert.true(reply!.text.includes('Node 24 and npm 11 are installed. pnpm is not.'))
    await a11yAudit()
  })
})
