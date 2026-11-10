import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TraceCollapsibleHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockTrace from 'docs-app/examples/code-block-trace'

module('Example | code-block-trace', function (hooks) {
  setupRenderingTest(hooks)

  test("small code blocks in a trace's rows, which keep their own text colour", async function (assert) {
    await render(<template><CodeBlockTrace /></template>)
    const [ran, failed] = TraceCollapsibleHarness.findAll()
    const output = ran!.find(CodeBlockHarness)
    assert.strictEqual(output.size, 'sm')
    assert.true(output.isWrapped)
    assert.strictEqual(getComputedStyle(output.content).maxHeight, '256px', 'max-h-64')
    assert.true(failed!.line.isError)
    const error = failed!.find(CodeBlockHarness)
    assert.strictEqual(error.variant, 'destructive')
    assert.true(error.code.includes('EADDRINUSE'))
    assert.notStrictEqual(
      getComputedStyle(output.element).color,
      getComputedStyle(ran!.content.firstElementChild!).color,
      'the block sets its own colour, not the trace content muted one',
    )
    await a11yAudit()
  })
})
