import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TraceHarness, TraceLineHarness } from '@ember-joinery/test-support'
import TraceStatic from 'docs-app/examples/trace-static'

module('Example | trace-static', function (hooks) {
  setupRenderingTest(hooks)

  test('one line on its own, read as text', async function (assert) {
    await render(<template><TraceStatic /></template>)
    const trace = new TraceHarness()
    assert.deepEqual(trace.titles, ['Created branch fix/frozen-lockfile'])
    const line = new TraceLineHarness()
    assert.strictEqual(line.control, null, 'nothing wraps it, so it is not a tab stop')
    assert.strictEqual(line.icons.length, 1)
    assert.strictEqual(line.status, null)
    await a11yAudit()
  })
})
