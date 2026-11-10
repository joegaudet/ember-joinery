import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TraceCollapsibleHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import TraceCollapsibleDemo from 'docs-app/examples/trace-collapsible'

module('Example | trace-collapsible', function (hooks) {
  setupRenderingTest(hooks)

  test('a closed row that opens onto the command output', async function (assert) {
    await render(<template><TraceCollapsibleDemo /></template>)
    const row = new TraceCollapsibleHarness()
    assert.false(row.isOpen, 'rows start closed')
    assert.strictEqual(row.label, 'Ran node --version')
    await row.open()
    const output = row.find(CodeBlockHarness)
    assert.strictEqual(output.size, 'sm')
    assert.true(output.isWrapped)
    assert.strictEqual(output.code, '$ node --version\nv24.18.0')
    await a11yAudit()
  })
})
