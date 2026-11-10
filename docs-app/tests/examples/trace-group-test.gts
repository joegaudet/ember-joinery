import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TraceHarness } from '@ember-joinery/test-support'
import TraceGroupDemo from 'docs-app/examples/trace-group'

module('Example | trace-group', function (hooks) {
  setupRenderingTest(hooks)

  test('three lines next to each other in one trace', async function (assert) {
    await render(<template><TraceGroupDemo /></template>)
    const trace = new TraceHarness()
    assert.deepEqual(trace.titles, [
      'Searched for minimumReleaseAge',
      'Read pnpm-workspace.yaml',
      'Ran pnpm install',
    ])
    assert.strictEqual(getComputedStyle(trace.element).rowGap, '8px', 'gap-2 between them')
    await a11yAudit()
  })
})
